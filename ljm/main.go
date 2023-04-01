package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	// Import Kubernetes client libraries
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
    "k8s.io/client-go/tools/remotecommand"
	"k8s.io/client-go/util/homedir"
	"k8s.io/apimachinery/pkg/util/wait"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	"k8s.io/apimachinery/pkg/watch"
	yamlutil "k8s.io/apimachinery/pkg/util/yaml"
)

type LJMConfig struct {
	ManifestDir string
}

func loadConfig() LJMConfig {
	// Load the LJM application manifest directory from an environment variable or a configuration file
	manifestDir := os.Getenv("LJM_MANIFEST_DIR")
	if manifestDir == "" {
		// Fallback to a default directory if not set
		manifestDir = "/path/to/default/manifests"
	}

	return LJMConfig{
		ManifestDir: manifestDir,
	}
}

func listManifests(config LJMConfig) {
	// List available LJM application manifests (plain YAML)
	files, err := ioutil.ReadDir(config.ManifestDir)
	if err != nil {
		fmt.Println("Error reading manifest directory:", err)
		return
	}

	for _, file := range files {
		if filepath.Ext(file.Name()) == ".yaml" {
			fmt.Println(file.Name())
		}
	}
}

func waitForPodRunning(clientset *kubernetes.Clientset, pod *corev1.Pod) (*corev1.Pod, error) {
	var runningPod *corev1.Pod
	err := wait.PollImmediate(time.Second, 5*time.Minute, func() (bool, error) {
		p, err := clientset.CoreV1().Pods(pod.Namespace).Get(context.Background(), pod.Name, metav1.GetOptions{})
		if err != nil {
			return false, err
		}
		if p.Status.Phase == corev1.PodRunning {
			runningPod = p
			return true, nil
		}
		return false, nil
	})
	return runningPod, err
}

func attachToContainerStreams(clientset *kubernetes.Clientset, pod *corev1.Pod, containerName string) error {
	req := clientset.CoreV1().RESTClient().Post().
		Resource("pods").
		Name(pod.Name).
		Namespace(pod.Namespace).
		SubResource("attach")
	req.VersionedParams(&corev1.PodAttachOptions{
		Container: containerName,
		Stdin:     true,
		Stdout:    true,
		Stderr:    true,
		StdinOnce: false,
		TTY:       false,
	}, metav1.ParameterCodec)

	exec, err := remotecommand.NewSPDYExecutor(clientset.RESTConfig(), "POST", req.URL())
	if err != nil {
		return err
	}

	err = exec.Stream(remotecommand.StreamOptions{
		Stdin:  os.Stdin,
		Stdout: os.Stdout,
		Stderr: os.Stderr,
		Tty:    false,
	})
	return err
}

func run(config LJMConfig, command string) {
	clientset, err := getKubernetesClient()
	if err != nil {
		fmt.Println("Error getting Kubernetes client:", err)
		return
	}

	manifestFile := filepath.Join(config.ManifestDir, command+".yaml")
	pod, err := createPodFromManifest(clientset, manifestFile)
	if err != nil {
		fmt.Println("Error creating pod from manifest:", err)
		return
	}

	fmt.Printf("Pod %s created, waiting for it to be running...\n", pod.Name)
	runningPod, err := waitForPodRunning(clientset, pod)
	if err != nil {
		fmt.Println("Error waiting for pod to be running:", err)
		return
	}

	fmt.Printf("Attaching to pod %s container %s...\n", runningPod.Name, runningPod.Spec.Containers[0].Name)
	err = attachToContainerStreams(clientset, runningPod, runningPod.Spec.Containers[0].Name)
	if err != nil {
		fmt.Println("Error attaching to container streams:", err)
		return
	}
}

func main() {
	// ...

	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "list":
			listManifests(config)
			return
		case "run":
			if len(os.Args) < 3 {
				fmt.Println("Usage: ljm run <command>")
				return
			}
			run(config, os.Args[2])
		default:
			fmt.Printf("Unknown command: %s\n", os.Args[1])
		}
	}
}



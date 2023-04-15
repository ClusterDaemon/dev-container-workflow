package main

import (
	"context"
	"fmt"
    "io"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"
    "text/template"

	// Import Kubernetes client libraries
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
    "k8s.io/client-go/tools/remotecommand"
	"k8s.io/client-go/util/homedir"
	"k8s.io/apimachinery/pkg/util/wait"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	yamlutil "k8s.io/apimachinery/pkg/util/yaml"
)

type LJMConfig struct {
	ManifestDir    string
	KubeconfigPath string
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

func getKubernetesClient() (*kubernetes.Clientset, *rest.Config, error) {
	var config *rest.Config
	var err error

	if home := homedir.HomeDir(); home != "" {
		kubeconfig := filepath.Join(home, ".kube", "config")
		if _, err := os.Stat(kubeconfig); !os.IsNotExist(err) {
			config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
			if err != nil {
				return nil, nil, err
			}
		}
	}

	if config == nil {
		config, err = rest.InClusterConfig()
		if err != nil {
			return nil, nil, err
		}
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, nil, err
	}

	return clientset, config, nil
}

func createPodFromManifest(clientset *kubernetes.Clientset, manifestFile string) (*corev1.Pod, error) {
	file, err := os.Open(manifestFile)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	decoder := yamlutil.NewYAMLOrJSONDecoder(file, 1024)
	scheme := runtime.NewScheme()
	corev1.AddToScheme(scheme)
	decode := serializer.NewCodecFactory(scheme).UniversalDeserializer().Decode

	var pod *corev1.Pod
	for {
		ext := runtime.RawExtension{}
		if err := decoder.Decode(&ext); err != nil {
			if err == io.EOF {
				break
			}
			return nil, err
		}
		obj, _, err := decode(ext.Raw, nil, nil)
		if err != nil {
			return nil, err
		}
		if p, ok := obj.(*corev1.Pod); ok {
			pod = p
			break
		}
	}

	if pod == nil {
		return nil, fmt.Errorf("no pod found in manifest file %s", manifestFile)
	}

	pod, err = clientset.CoreV1().Pods(pod.Namespace).Create(context.Background(), pod, metav1.CreateOptions{})
	if err != nil {
		return nil, err
	}

	return pod, nil
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

func attachToContainerStreams(clientset *kubernetes.Clientset, restConfig *rest.Config, pod *corev1.Pod, containerName string) error {
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
		TTY:       false,
	}, metav1.ParameterCodec)

	exec, err := remotecommand.NewSPDYExecutor(restConfig, "POST", req.URL())
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
	clientset, restConfig, err := getKubernetesClient()
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
	err = attachToContainerStreams(clientset, restConfig, runningPod, runningPod.Spec.Containers[0].Name)
	if err != nil {
		fmt.Println("Error attaching to container streams:", err)
		return
	}
}

func main() {
    config := loadConfig()

    if len(os.Args) < 2 {
        fmt.Println("Usage:")
        fmt.Println("  longshoreman list")
        fmt.Println("  longshoreman run <command>")
        os.Exit(1)
    }

    switch os.Args[1] {
    case "list":
        listManifests(config)
    case "run":
        if len(os.Args) < 3 {
            fmt.Println("Usage: longshoreman run <command>")
            os.Exit(1)
        }
        run(config, os.Args[2])
    default:
        fmt.Printf("Unknown command: %s\n", os.Args[1])
        os.Exit(1)
    }
}


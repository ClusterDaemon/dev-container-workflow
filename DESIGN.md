# Remote Development Shell Workflow on Kubernetes

This document outlines the design of a remote development shell workflow built on Kubernetes (code-named "Longshoreman"). The system is designed to be containerized, distributed, and accessible via a web browser through ttyd. It features built-in text and code manipulation tools via traditional shell applications, and extendable functionality through management of Kubernetes primitives. Persistent data is shared between the main shell container and extension jobs/pods using a shared ReadWriteMany filesystem. NFS works well, but any ReadWriteMany storage class will do. Data may also be sent to extention pods via stdin and stdout, as long as those pods are managed as a Longshoreman App.

## Table of Contents

- [System Overview](#system-overview)
- [Architecture](#architecture)
  - [Main Shell Container](#main-shell-container)
  - [Longshorman Apps](#longshoreman-apps)
  - [Shared Filesystem](#shared-filesystem)
  - [Job Management](#job-management)
- [Implementation Steps](#implementation-steps)

## System Overview

The proposed system is a remote development shell workflow with the following features:

- Built within containers
- Orchestrated via Kubernetes, delivered via Helm
- Accessible remotely via a web browser (using ttyd) or via SSH
- Built-in text and code manipulation programs (at least)
- Extendable by running applications via Kubernetes pods with pre-defined manifests
- Strong consistent shared state for extensions via a shared filesystem (e.g., NFS)

## Architecture

The architecture consists of the following components:

- Remote Shell
  - File transfer via zmodem
  - Accessible via SSH or in-browser via ttyd
- Main Shell Container (MSC)
  - Bash shell with basic utilities
  - Entrypoint for all commands
  - Contains all components required for baseline text-based development (vim, tmux, sed, awk, grep, etc).
  - May have additional "built-in" applications installed, though doing so would require a sidecar or rebuild.
- Persistence
  - Longshoreman accomplishes persistence via a readWriteMany persistent volume. This is because persistence is meant to be shared with extension applications in the same cluster, and the nature of those extension applications is varied and unknown.
  - Additional or alternative methods of persistence may be defined, both for the main shell container and extension applications. However, this use-case is not addressed via the Helm chart.
- Extension applications
  - Extensions are not installed, they are declared in a plain YAML K8s manifest (one directory per extension).
  - Extensions must declare all of the components they need to work in their directories, though may reference existing systems and objects. Extensions should be portable.
  - Extensions must declare a "run workload", which defines the workload that is used to run the extension application. Longshoreman will manage the state of this workload. It should usually be a singular bare pod with few exceptions.
  - Extensions may include daemons, though these should be run as StefulSet, Deployment, Daemonset, or similar. These daemons will be executed on extension initialization, NOT during extension command run. This is support command dependencies with proper load ordering to avoid delays and errors in extension command execution.
  - Extensions are initialized when Longshoreman starts, which equates to applying all but the run workload.
  - The extension run workload is only executed when the extension is called via the main shell container.
  - Extensions are shell aliases, which call the Longshoreman extension manager to operate the run workload. Run workloads are not meant to be run directly, as the extension manager supplies the run workload with configuration via YAML document merging before submitting the run workload manifest to the cluster.
  - Extensions are meant to accomplish an identical experience to running commands locally, despite running in a remote container. The default location for run workloads is defined either in the extension manifest, or at runtime. If no location is supplied, it will be applied to the same cluster and namespace that the main shell container is running in.
  - Extensions must allow for typical shell execution semantics, where input and output streams traverse via the main shell container as a cental hub. Because of this, the MSC must have the resources available to sustain the input and output traffic of running extensions. This can be mitigated using the persistence layer, or by explicitly configuring extension output and input outside of invocation within its run workload manifest.

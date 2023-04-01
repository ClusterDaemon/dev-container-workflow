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
- Delivered via Kubernetes
- Accessible remotely via a web browser (using ttyd)
- Built-in text and code manipulation programs
- Extendable by running applications via Kubernetes jobs
- Strongly consistent state management via a shared POSIX filesystem (e.g., NFS)

## Architecture

The architecture consists of the following components:

- Main Shell Container (MSC)
  - Bash shell with utilities
  - Accessible in a browser via ttyd
  - Responsible for job control
  - ZMODEM file transfer support
- Longshoreman Apps
  - Integrated with the system as shell commands via Longshoreman Job Manager (LJM)
  - Executed as a Kubernetes pod or job+pod, managed by LJM.
  - Remote IO support, enabling support for stream redirection, herestrings, heredocs, and pipes via the MSC.
- Longshoreman Job Manager
  - Go binary that is responsible for managing pod or job manifests in K8s and responding to feedback
  - Handles container I/O streams to and from MSC.

### Main Shell Container

The main shell container serves as the primary environment for the user. It is accessible via a web browser through ttyd. This container includes the following features:

- Multiplexing via TMUX
- Editing and IDE via VIM
- Persistent working state
- Built-in text and code manipulation programs (e.g., grep, sed, awk)
- Extensibility via Longshoreman Jobs

### Longshoreman Apps

Kubernetes pods extend the functionality of the main shell container. They behave like traditional GNU POSIX compliant command-line applications. They generally must:

- Accept stdin
- Produce stdout and stderr
- Return exit codes
- Resolve provided file paths

Longshoreman Apps are packaged via container images and K8s manifests. They must be either jobs or pods, or a similar system that implements the job or pod spec. The Longshoreman Job Manager (LJM) must be able to find a manifest directory that matches the name of the application, and there must be exactly one job or pod object in that manifest.

### Shared Filesystem

A shared filesystem, such as NFS, may be used to provide a strongly consistent persistence store between the main shell container and Longshoreman Apps. This filesystem must be POSIX compliant and accessible to the app that extends functionality.

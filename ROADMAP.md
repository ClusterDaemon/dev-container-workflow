Broad strokes, get this running in the following order:

1) Main shell container
2) Remote shell service to the MSC
3) Shared persistence layer
4) Extension manager and example extension manifest

## Main Shell Container
  - Basic development environment with very low overhead (no cloud tools, no build tools, etc)
  - State persistence for TMUX and VIM. The MSC must be able to be terminated without a loss in working state.
  - Non-root user with read-only root filesystem and no capabilities. Since this is a remote shell, it should be teated as a potential escalation or lateral movement point.
  - Installation via Helm

## Remote Shell Service
  - Automatic attach to existing tmux session
  - Kubernetes service exposes ttyd
  - Gateway API exposes SSH (Unexplored! May change, but seems best for TCP ingress)
  - May be integrated into MSC, or run as sidecar (Unexplored, matters when it comes to init and service health)

## Shared Persistence Layer
  - Install via Helm for each release
  - Optionally use existing resource
  - ReadWriteMany by default
  - Manage backups (off by default?)

## Extension Manager
  - Affected too heavily by the previous systems to adequately plan beyond the existing design doc.

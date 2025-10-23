## Dispatcher SDK

[![build_status](https://github.com/aem-design/docker-dispatcher-sdk/workflows/build/badge.svg)](https://github.com/aem-design/docker-dispatcher-sdk/actions?query=workflow%3Abuild)
[![github license](https://img.shields.io/github/license/aem-design/docker-dispatcher-sdk)](https://github.com/aem-design/docker-dispatcher-sdk)
[![github issues](https://img.shields.io/github/issues/aem-design/docker-dispatcher-sdk)](https://github.com/aem-design/docker-dispatcher-sdk)
[![github last commit](https://img.shields.io/github/last-commit/aem-design/docker-dispatcher-sdk)](https://github.com/aem-design/docker-dispatcher-sdk)
[![github repo size](https://img.shields.io/github/repo-size/aem-design/docker-dispatcher-sdk)](https://github.com/aem-design/docker-dispatcher-sdk)
[![docker stars](https://img.shields.io/docker/stars/aemdesign/dispatcher-sdk)](https://hub.docker.com/r/aemdesign/dispatcher-sdk)
[![docker pulls](https://img.shields.io/docker/pulls/aemdesign/dispatcher-sdk)](https://hub.docker.com/r/aemdesign/dispatcher-sdk)

AEM Dispatcher SDK Docker image with multi-architecture support (amd64/arm64).

Please go to docs/README.html to find the documentation.

## Docker Images

Images are available on both registries:
- **Docker Hub**: `aemdesign/dispatcher-sdk`
- **GitHub Container Registry**: `ghcr.io/aem-design/dispatcher-sdk`

### Tags

- `latest` - Latest build from main branch
- `main` - Latest build from main branch
- `2.0.x` - Version tags (pushed when git tags are created)

## Running

```bash
docker run -d --rm -v ${PWD}/src:/mnt/dev/src -p 8080:80 -e AEM_PORT=4503 -e AEM_HOST=host.docker.internal aemdesign/dispatcher-sdk:latest
```

### Environment Variables

- `AEM_HOST` - AEM instance hostname (default: `host.docker.internal`)
- `AEM_PORT` - AEM instance port (default: `4503`)

## Development

### CI/CD Pipeline

The project uses GitHub Actions for continuous integration and deployment:

- **Multi-platform builds**: Images are built for both `linux/amd64` and `linux/arm64`
- **Automated testing**: 
  - Linux testing on `ubuntu-latest` with amd64 image
  - ARM64 testing via QEMU emulation on `ubuntu-latest`
- **Image analysis**: Uses `dive` for Docker image layer analysis
- **Dual registry push**: Automatically pushes to Docker Hub and GitHub Container Registry
- **Git tag versioning**: Pushing a git tag (e.g., `2.0.188`) automatically creates a corresponding Docker image tag

#### Pipeline Jobs

1. **build** (Linux): Builds, tests, and pushes multi-arch images (amd64/arm64)
2. **test-arm64** (QEMU Emulation): Validates arm64 image functionality

#### ARM64 Known Limitations

- **mod_qos disabled**: The `mod_qos` (Quality of Service) Apache module is automatically disabled on ARM64 builds due to binary incompatibility. All other functionality remains intact.

### Monitoring Pipeline Status

The `get-action-logs.ps1` PowerShell script provides easy access to GitHub Actions workflow status and logs.

#### Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Install: `winget install --id GitHub.cli`
- Authenticate: `gh auth login`

#### Quick Start

```powershell
# Check current commit's pipeline status (saves logs to logs/ folder by default)
.\get-action-logs.ps1

# Wait for pipeline to complete
.\get-action-logs.ps1 -WaitForCompletion

# Show logs in console
.\get-action-logs.ps1 -ShowLogs

# Force re-download logs
.\get-action-logs.ps1 -Force
```

#### Advanced Options

```powershell
# View specific run's logs
.\get-action-logs.ps1 -RunId 12345678 -ViewLogs

# Download logs as zip
.\get-action-logs.ps1 -RunId 12345678 -Download

# Watch running workflow in real-time
.\get-action-logs.ps1 -Watch

# List recent runs
.\get-action-logs.ps1 -Limit 10

# Filter by status
.\get-action-logs.ps1 -Status failure

# Filter by workflow
.\get-action-logs.ps1 -Workflow "build.yml"

# Disable auto-save
.\get-action-logs.ps1 -SaveLogs:$false
```

#### Saved Logs

Logs are automatically saved to the `logs/` folder with the following naming convention:

```
logs/run-{runId}-{commitSha}-{workflowName}-{conclusion}.log
```

Example: `logs/run-18709640324-780320e-build-success.log`

**Note**: The script automatically detects if logs have already been downloaded and skips re-downloading them. Use `-Force` to re-download existing logs.

See full script documentation: `Get-Help .\get-action-logs.ps1 -Full`

### Creating a New Release

To create a new version release:

```bash
# Tag the commit
git tag 2.0.188
git push origin 2.0.188
```

This will automatically:
1. Trigger the build workflow
2. Build multi-platform Docker images
3. Tag images as `aemdesign/dispatcher-sdk:2.0.188`
4. Push to both Docker Hub and GitHub Container Registry
5. Create a GitHub release

## License

See [LICENSE](LICENSE) file for details.

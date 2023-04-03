## Dispatcher SDK

[![build_status](https://github.com/aem-design/docker-dispatcher-sdk/workflows/build/badge.svg)](https://github.com/aem-design/docker-dispatcher-sdk/actions?query=workflow%3Abuild)
[![github license](https://img.shields.io/github/license/aem-design/dispatcher-sdk)](https://github.com/aem-design/dispatcher-sdk)
[![github issues](https://img.shields.io/github/issues/aem-design/dispatcher-sdk)](https://github.com/aem-design/dispatcher-sdk)
[![github last commit](https://img.shields.io/github/last-commit/aem-design/dispatcher-sdk)](https://github.com/aem-design/dispatcher-sdk)
[![github repo size](https://img.shields.io/github/repo-size/aem-design/dispatcher-sdk)](https://github.com/aem-design/dispatcher-sdk)
[![docker stars](https://img.shields.io/docker/stars/aemdesign/dispatcher-sdk)](https://hub.docker.com/r/aemdesign/dispatcher-sdk)
[![docker pulls](https://img.shields.io/docker/pulls/aemdesign/dispatcher-sdk)](https://hub.docker.com/r/aemdesign/dispatcher-sdk)
[![github release](https://img.shields.io/github/release/aem-design/dispatcher-sdk)](https://github.com/aem-design/dispatcher-sdk)

Please go to docs/README.html to find the documentation.

### Running

```bash
docker run -d --rm -v ${PWD}/src:/mnt/dev/src -p 8080:80 -e AEM_PORT=4503 -e AEM_HOST=host.docker.internal aemdesign/dispatcher-sdk:2.0.169
``` 

# CI/CD Patterns

## Docker Build and Push Must Share a CI Stage

Splitting `docker build` and `docker push` across separate CI stages fails silently — the push stage runs on a different runner instance that doesn't have the locally-built image. Build and push in the same job.

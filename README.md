# MULTI ARCHITECTURE CONTAINER IMAGES

# INSTALL DOCKER AND CONTAINER TOOLS
```
apt install docker.io skopeo jq
```

# INSTALL BUILDX DOCKER PLUGIN
```
mkdir -p $HOME/.docker/cli-plugins
```
```
BUILDX_VERSION=$(curl -fsSL https://github.com/docker/buildx/releases | grep -m 1 -Eo 'v[0-9]+\.[0-9]+\.[0-9]*')
curl -fsSL https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-amd64 \
  -o $HOME/.docker/cli-plugins/docker-buildx
chmod +x $HOME/.docker/cli-plugins/docker-buildx
```

# CHECK DOCKER PLUGINS
```
docker info
```

# LOCAL REGISTRY
```
docker run -d --rm --name registry -p 5000:5000 registry:2
```

# IMAGE BUILDER
```
docker buildx create --name img-builder --use --driver docker-container \
--driver-opt image=moby/buildkit:v0.10.3 --driver-opt network=host
```

# DOCKERFILE
```
cat <<'EOF'> Dockerfile 
FROM nginx:stable
RUN nginx -v
HEALTHCHECK --start-period=1s --timeout=10s --interval=10s \
  CMD curl -fsSL -H 'User-Agent: HealthCheck' http://127.0.0.1:80
EOF
```

# BUILD TO DOCKER REGISTRY WITH BUILDX
```
docker buildx build --platform=linux/arm64/v8,linux/amd64 --pull --push \
-t 127.0.0.1:5000/my-docker-image:v1 --progress=plain .
```

# CHECK MULTI ARCHITECTURE
```
docker pull --platform arm64 127.0.0.1:5000/my-docker-image:v1
```
```
docker inspect 127.0.0.1:5000/my-docker-image:v1 | grep Architecture
```
```
docker pull --platform amd64 127.0.0.1:5000/my-docker-image:v1
```
```
docker inspect 127.0.0.1:5000/my-docker-image:v1 | grep Architecture
```

# TEST
```
docker run -it --rm 127.0.0.1:5000/my-docker-image:v1
```

# BUILD TO OCI TAR WITH BUILDX
```
docker buildx build --platform=linux/arm64/v8,linux/amd64 --pull \
-o type=oci,dest=- --progress=plain . > my-oci-image.tar
```
```
skopeo inspect --raw oci-archive:my-oci-image.tar | \
jq -r '.manifests[].platform.architecture'
skopeo inspect oci-archive:my-oci-image.tar --override-arch=amd64
skopeo inspect oci-archive:my-oci-image.tar --override-arch=arm64
```

# COPY OCI IMAGE TO DOCKER IMAGE WITH SKOPEO
```
skopeo copy oci-archive:my-oci-image.tar docker-archive:my-docker-image.tar --override-arch=amd64
```
```
docker load -i my-docker-image.tar | awk -F':' '{print $NF}' | xargs -i docker tag {} my-docker-image
```
# TEST
```
docker run -it --rm my-docker-image
```

# PUSH TO DOCKER REGISTRY WITH SKOPEO
```
skopeo copy oci-archive:my-oci-image.tar docker://127.0.0.1:5000/my-docker-image:v1 \
--dest-tls-verify=false
```
```
docker pull 127.0.0.1:5000/my-docker-image:v1
```
```
docker inspect 127.0.0.1:5000/my-docker-image:v1
```

# TEST
```
docker run -d --rm --name nginx 127.0.0.1:5000/my-docker-image:v1
```

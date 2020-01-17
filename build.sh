#!/bin/bash

echo "==> Determining TAG"
TAG=$2
if [ -z "$TAG" ]; then
    TAG=$(git rev-list -n 1 "$(git rev-parse --abbrev-ref HEAD)")
    echo "Determined TAG from HEAD: $TAG"
else
    echo "Using TAG from parameter: $TAG"
fi

echo "==> Determining SHA"
SHA=$(git rev-parse "$TAG")
if [ "$?" != "0" ]; then
    echo "ERROR: could not determine SHA"
    exit 1
fi

DOCKER_REPO="$(cat REPO_NAME)"

echo "==> Detecting GIT params to pass to Dockerfile"
BUILD_TOOLS_COMMIT="$(git rev-parse --short HEAD)"
echo "    BUILD_TOOLS_COMMIT: $BUILD_TOOLS_COMMIT"
GIT_DESCRIBE="$(git describe)"
echo "    GIT_DESCRIBE: $GIT_DESCRIBE"

echo "==> Creating source archive"
(./archive.sh $SHA) > /dev/null
if [ "$?" != "0" ]; then
    echo "ERROR: failed to invoke (./archive.sh $SHA)"
    exit 1
fi

ARCHIVE_PATH=/tmp/$SHA.tar.gz
mv ./$SHA.tar.gz "$ARCHIVE_PATH"
echo "Created archive $ARCHIVE_PATH"

SRC_PATH=/tmp/$SHA
mkdir -p $SRC_PATH

echo "Extracting to $SRC_PATH"
(cd /tmp/$SHA && tar -xf $ARCHIVE_PATH)

echo "Removing VCS related files"
find "${SRC_PATH}" -name .git -exec rm -rf {} \; &> /dev/null

latest=0
if [ -z "$DOMOTICZ_VERSION" ]; then
    DOMOTICZ_VERSION="$(curl -sX GET https://api.github.com/repos/domoticz/domoticz/releases/latest | jq -r .tag_name)"
    DOMOTICZ_COMMIT="$DOMOTICZ_VERSION"
    latest=1
fi

if [ -z "$DOMOTICZ_COMMIT" ]; then
    DOMOTICZ_COMMIT="$(curl -sX GET https://api.github.com/repos/domoticz/domoticz/commits/development | jq -r .sha)"
    DOMOTICZ_VERSION="nigthly"
fi

echo "==> Building docker image from $SHA"
echo "Creating docker image $DOCKER_REPO"
echo "  context: $SRC_PATH"
echo "  commit: $DOMOTICZ_COMMIT"

docker build --build-arg DOMOTICZ_VERSION="$DOMOTICZ_VERSION" --build-arg SOURCE_COMMIT="$BUILD_TOOLS_COMMIT" --build-arg DOMOTICZ_COMMIT="$DOMOTICZ_COMMIT" -t "${DOCKER_REPO}:${DOMOTICZ_VERSION}" "$SRC_PATH" > /tmp/docker.build.log
if [ "$?" != "0" ]; then
    echo "ERROR: failed. See /tmp/docker.build.log"
    exit 1
fi

echo "==> Pushing docker image"

if [ $latest -eq 1 ]; then
    docker tag "$DOCKER_REPO:$DOMOTICZ_VERSION" "$DOCKER_REPO:latest"
fi

if [ "${1:-}" != "--skip-push" ]; then
    docker push "$DOCKER_REPO:$DOMOTICZ_VERSION"
    if [ $latest -eq 1 ]; then
        docker push "$DOCKER_REPO:latest"
    fi
fi


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

echo "==> Determining version ID"
VERSION=$(git describe "$TAG")
if [ "$?" != "0" ]; then
        echo "ERROR: could not determine version ID"
        exit 1
fi

DOCKER_REPO="$(cat REPO_NAME)"

echo "==> Detecting GIT params to pass to Dockerfile"
GIT_COMMIT="$(git rev-parse --short HEAD)"
echo "    GIT_COMMIT: $GIT_COMMIT"
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

echo "==> Building docker image from $SHA"
echo "Creating docker image $DOCKER_REPO"
echo "  context: $SRC_PATH"

if [ -z "$DOMOTICZ_COMMIT" ]; then
    DOMOTICZ_COMMIT="$VERSION"
fi

docker build --build-arg GIT_DESCRIBE="$GIT_DESCRIBE" --build-arg GIT_COMMIT="$GIT_COMMIT" --build-arg DOMOTICZ_COMMIT="$DOMOTICZ_COMMIT" -t "${DOCKER_REPO}:${VERSION}" "$SRC_PATH" > /tmp/docker.build.log
if [ "$?" != "0" ]; then
  echo "ERROR: failed. See /tmp/docker.build.log"
  exit 1
fi

echo "==> Pushing docker image"

docker tag "$DOCKER_REPO:$VERSION" "$DOCKER_REPO:latest"

if [ "${1:-}" != "--skip-push" ]; then
  docker push "$DOCKER_REPO:$VERSION"
  docker push "$DOCKER_REPO:latest"
  git push --tags &> /dev/null
fi


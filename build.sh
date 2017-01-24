#!/bin/bash -e

# Check if /var/run/docker.sock is mounted
if [[ ! -e "/var/run/docker.sock"  ]];
then
  echo "Error: Must mount /var/run/docker.sock into /var/run/docker.sock directory"
  exit 990
fi

# Check if src directory is not empty
if ( find /src -maxdepth 0 -empty | read v );
then
  echo "Error: Must mount Go source code into /src directory"
  exit 990
fi

#
# Optional DOCKERFILE env var to use the "-f" docker build switch
# forces docker to use a different dockerfile
#
dockerfile=""
if [[ ! -z "${DOCKERFILE}" ]];
then
  dockerfile="-f ${DOCKERFILE}"
fi

# Check if ./Dockerfile is in src directory 
if [[ ! -e "./${DOCKERFILE:-Dockerfile}" ]];
then
  echo "Error: Must have ./Dockerfile into /src directory"
  exit 990
fi

# Grab Go package name from canonical import path annotation (package main // import "github.com/fabriziopandini/hello") 
pkgName="$(go list -e -f '{{.ImportComment}}' 2>/dev/null || true)"

if [ -z "$pkgName" ];
then
  echo "Error: Must add canonical import path to root package"
  exit 992
fi

# Grab the last segment from the package name
name=${pkgName##*/}

# Grab the image tag name from command line arguments or default it to package name if not set explicitly
tagName=$1
tagName=${tagName:-"$name":latest}

# Grab just first path listed in GOPATH
goPath="${GOPATH%%:*}"

# Construct Go package path
pkgPath="$goPath/src/$pkgName"

# Set-up src directory tree in GOPATH
mkdir -p "$(dirname "$pkgPath")"

# Link source dir into GOPATH
ln -sf /src "$pkgPath"

# Get dependencies
echo "Get package dependencies"
(
   go get -t -d -v ./...
)

#
# Optional OUTPUT env var to use the "-o" go build switch
# forces build to write the resulting executable or object
# to the named output file
#
output=""
if [[ ! -z "${OUTPUT}" ]];
then
  output="-o ${OUTPUT}"
fi

# Compile statically linked version of package
echo "Building package $pkgName"
(
  CGO_ENABLED=${CGO_ENABLED:-0} \
  go build \
  -a \
  ${output} \
  --installsuffix cgo \
  --ldflags="${LDFLAGS:--s}" \
  $pkgName
)

# Build the image from the Dockerfile in the package directory
echo "Building image $tagName"
(
  docker build -t $tagName ${dockerfile} .
)
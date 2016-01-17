FROM drewcrawford/swift:latest
RUN apt-get update && apt-get install --no-install-recommends xz-utils -y
ADD https://github.com/AnarchyTools/atbuild/releases/download/0.3.0/atbuild-0.3.0-linux.tar.xz /atbuild.tar.xz
RUN tar xf atbuild.tar.xz -C /usr/local
ADD . /atpkg
WORKDIR atpkg
RUN atbuild run-tests
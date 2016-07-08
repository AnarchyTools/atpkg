FROM drewcrawford/buildbase:latest
RUN apt-get update && apt-get install atbuild -y
ADD . /atpkg
WORKDIR atpkg
RUN atbuild check

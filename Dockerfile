FROM ubuntu
MAINTAINER SvenDowideit@docker.com

RUN apt-get update && apt-get install -y puppet git

RUN puppet apply -e "tp::conf {'redis':  debug => true  }" --modulepath ../.


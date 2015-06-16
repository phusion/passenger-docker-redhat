FROM centos:centos7
MAINTAINER Phusion <info@phusion.nl>

ADD imgbuild /imgbuild

# control build type with build.sh arguments
RUN /imgbuild/generated_main_installer.sh

RUN rm -rf /imgbuild

CMD ["/sbin/my_init", "--skip-runit", "nginx"]

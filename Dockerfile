FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VPS_USER=root
ENV VPS_PASS=root
ENV ROOT_PASS=root
ENV SSH_PORT=2222
ENV HOSTNAME=kobir

WORKDIR /root

COPY bootstrap.sh /root/bootstrap.sh
RUN chmod +x /root/bootstrap.sh

EXPOSE 8080 2222

CMD ["/bin/bash", "/root/bootstrap.sh"]

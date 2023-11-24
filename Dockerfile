FROM docker.io/minio/mc as mc

FROM docker.io/goacme/lego:v4.14.2 as lego


FROM docker.io/library/alpine
RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories 
RUN apk add --no-cache gettext bash 

COPY --from=mc /usr/bin/mc /usr/bin/mc
ADD ./configs/mc.config /root/.mc/mc.config.tmpl
ADD ./configs/rclone.conf /root/.config/rclone/rclone.conf.tmpl

COPY --from=lego /usr/bin/lego /usr/bin/lego

ADD ./script.sh /usr/bin/lego.sh
RUN chmod +x /usr/bin/lego.sh

WORKDIR /workdir/

ENTRYPOINT [ "/usr/bin/lego.sh" ]

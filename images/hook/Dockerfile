FROM quay.io/gravitational/debian-tall:latest

RUN mkdir -p /root/cfssl
ADD *.json /root/cfssl/

ADD bin/cfssl \
    bin/cfssljson  \
        /usr/local/bin/
RUN chmod a+x /usr/local/bin/cfssl*

ADD hook.sh /hook.sh

RUN test -f /cleanup.sh && sh /cleanup.sh
ENTRYPOINT ["dumb-init", "/hook.sh"]

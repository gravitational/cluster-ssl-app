FROM quay.io/gravitational/debian-grande:latest

RUN apt-get update && \
    apt-get install --yes --no-install-recommends curl jq && \
    curl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl && \
	curl  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson && \
    mkdir -p /root/cfssl && \
    apt-get clean && \
    rm -rf \
        /var/lib/apt/lists/* \
        ~/.bashrc \
        /usr/share/doc/ \
        /usr/share/doc-base/ \
        /usr/share/man/ \
        /tmp/*

ADD *.json /root/cfssl/

RUN chmod a+x /usr/local/bin/cfssl*

ADD hook.sh /hook.sh

RUN test -f /cleanup.sh && sh /cleanup.sh
ENTRYPOINT ["dumb-init", "/hook.sh"]

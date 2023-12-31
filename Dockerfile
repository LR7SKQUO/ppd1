FROM alpine:edge AS builder
COPY --from=sliamb/prebuild-paopaodns /src/ /src/
COPY src/ /src/
RUN sh /src/build.sh
# JUST CHECK
RUN cp /src/Country-only-cn-private.mmdb.xz /tmp/ &&\
    cp /src/global_mark.dat /tmp/ &&\
    cp /src/data_update.sh /tmp/ &&\
    cp /src/dnscrypt-resolvers/public-resolvers.md /tmp/ &&\
    cp /src/dnscrypt-resolvers/public-resolvers.md.minisig /tmp/ &&\
    cp /src/dnscrypt-resolvers/relays.md /tmp/ &&\
    cp /src/dnscrypt-resolvers/relays.md.minisig /tmp/ &&\
    cp /src/dnscrypt.toml /tmp/ &&\
    cp /src/force_cn_list.txt /tmp/ &&\
    cp /src/force_nocn_list.txt /tmp/ &&\
    cp /src/init.sh /tmp/ &&\
    cp /src/mosdns /tmp/ &&\
    cp /src/mosdns.yaml /tmp/ &&\
    cp /src/named.cache /tmp/ &&\
    cp /src/redis.conf /tmp/ &&\
    cp /src/repositories /tmp/ &&\
    cp /src/unbound /tmp/ &&\
    cp /src/unbound-checkconf /tmp/ &&\
    cp /src/unbound.conf /tmp/ &&\
    cp /src/unbound_custom.conf /tmp/ &&\
    cp /src/trackerslist.txt.xz /tmp/ &&\
    cp /src/watch_list.sh /tmp/ &&\
    cp /src/redis-server /tmp/
FROM alpine:edge
COPY --from=builder /src/ /src/
# export files
VOLUME /data
WORKDIR /data
ENTRYPOINT ["/bin/sh", "-c", "rm -rf /data/src.tar && tar -cvf /data/src.tar /src && echo 'done!' && tail -f /dev/null"]
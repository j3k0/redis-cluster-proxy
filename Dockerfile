FROM alpine:3.20 as build

RUN apk add --no-cache gcc musl-dev linux-headers openssl-dev make git

RUN addgroup -S app && adduser -S -G app app 
RUN chown -R app:app /usr/local

WORKDIR /tmp
COPY . redis-cluster-proxy
RUN chown -R app redis-cluster-proxy
USER app
RUN cd redis-cluster-proxy && make -j4 install

FROM alpine:3.20 as runtime

RUN apk add --no-cache libstdc++
RUN apk add --no-cache strace
RUN apk add --no-cache python3
RUN apk add --no-cache redis

RUN addgroup -S app && adduser -S -G app app 
COPY --chown=app:app --from=build /usr/local/bin/redis-cluster-proxy /usr/local/bin/redis-cluster-proxy
RUN chmod +x /usr/local/bin/redis-cluster-proxy
RUN ldd /usr/local/bin/redis-cluster-proxy

RUN mkdir -p /usr/local/etc/redis-cluster-proxy
RUN mkdir -p /usr/local/run/redis-cluster-proxy
RUN chown -R app:app /usr/local
VOLUME /usr/local/etc/redis-cluster-proxy
VOLUME /usr/local/run/redis-cluster-proxy

# Now run in usermode
USER app
WORKDIR /home/app

ENTRYPOINT ["/usr/local/bin/redis-cluster-proxy"]
EXPOSE 7777
CMD ["redis-cluster-proxy"]


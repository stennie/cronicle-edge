# build: docker build --no-cache -t cronicle:bundle -f Dockerfile .
# docker tag cronicle:dev cronicle/cronicle:edge
# test run: docker run --rm -it  -p 3019:3012 -e CRONICLE_manager=1 cronicle:bundle bash
# then type manager or worker

FROM alpine:3.17 as build
RUN apk add --no-cache bash nodejs npm 
COPY . /build
WORKDIR /build
RUN ./bundle /dist --s3 --lmdb

FROM alpine:3.17
RUN apk add --no-cache bash nodejs tini util-linux bash openssl procps coreutils curl tar jq

# non root user for shell plugin
ARG CRONICLE_UID=1000
ARG CRONICLE_GID=1099
RUN  addgroup cronicle --gid $CRONICLE_GID && adduser -D -h /opt/cronicle -u $CRONICLE_UID -G cronicle cronicle

COPY --from=build /dist /opt/cronicle

ENV PATH "/opt/cronicle/bin:${PATH}"
ENV CRONICLE_foreground=1
ENV CRONICLE_echo=1
ENV TZ=America/New_York 

WORKDIR /opt/cronicle 

# protect sensitive folders
RUN  mkdir -p /opt/cronicle/data /opt/cronicle/conf && chmod 0700 /opt/cronicle/data /opt/cronicle/conf

ENTRYPOINT ["/sbin/tini", "--"]

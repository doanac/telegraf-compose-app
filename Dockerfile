FROM golang:alpine as build

RUN \
	apk add git make upx && \
	git clone https://github.com/influxdata/telegraf && \
	cd telegraf && \
	git checkout v1.31.3 && \
	make build_tools

COPY template.conf /src/

RUN \
	cd telegraf && \
	./tools/custom_builder/custom_builder --config /src/template.conf && \
	upx -o /telegraf ./telegraf

FROM alpine
RUN  apk add openssl
COPY --from=build /telegraf /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh

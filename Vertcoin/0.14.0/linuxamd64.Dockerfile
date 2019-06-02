FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu wget unzip

ENV BITCOIN_VERSION 0.14.0
ENV BITCOIN_URL https://github.com/vertcoin-project/vertcoin-core/releases/download/0.14.0/vertcoind-v0.14.0-linux-amd64.zip
ENV BITCOIN_SHA256 9ae133768306ef9c751e128d3592b3e998e56f08423ac496d2474426446eebe5

# install bitcoin binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.zip "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.zip" | sha256sum -c - \
	&& mkdir bin \
	&& unzip bitcoin.zip -d bin \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
	&& echo "0b843df6d86e270c5b0f5cbd3c326a04e18f4b7f9b8457fa497b0454c4b138d7 gosu" | sha256sum -c -

FROM debian:stretch-slim
COPY --from=builder "/tmp/bin" /usr/local/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r vertcoin && useradd -r -m -g vertcoin vertcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R vertcoin:vertcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/vertcoin/.vertcoin \
	&& chown -h vertcoin:vertcoin /home/vertcoin/.vertcoin

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5889 5888 15889 15888 18443 18444
CMD ["vertcoind"]
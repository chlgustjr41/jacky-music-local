FROM alpine:3.19
RUN apk add --no-cache curl docker-cli docker-cli-compose jq
COPY monitor.sh /monitor.sh
RUN chmod +x /monitor.sh
ENTRYPOINT ["/monitor.sh"]

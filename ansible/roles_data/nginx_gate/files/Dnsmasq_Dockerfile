FROM alpine:latest

RUN apk update
RUN apk --no-cache add dnsmasq

CMD [ "nohup", "dnsmasq", "--no-daemon"]

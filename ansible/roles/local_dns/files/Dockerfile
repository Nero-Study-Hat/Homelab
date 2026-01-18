FROM alpine:3.16

RUN apk update
RUN apk --no-cache add dnsmasq

CMD [ "nohup", "dnsmasq", "--no-daemon"]

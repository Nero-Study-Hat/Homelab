FROM alpine:latest

RUN apk update
RUN apk --no-cache add dnsmasq

COPY dnsmasq.conf /etc/dnsmasq.conf

CMD [ "nohup", "dnsmasq", "--no-daemon"]

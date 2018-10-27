# Base image
FROM nginx:alpine

# Install dependencies
RUN apk add bash

COPY nginx.conf /tmp/docker.nginx
COPY wait-for-it.sh /tmp/wait-for-it.sh

RUN chmod +x /tmp/wait-for-it.sh

EXPOSE 80

CMD [ "/tmp/wait-for-it.sh", "appeals-app:3000"]
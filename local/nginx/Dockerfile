# Base image
FROM nginx:alpine

# Install dependencies
RUN apk add bash

COPY nginx.conf /tmp/docker.nginx
COPY wait-for-it.sh /tmp/wait-for-it.sh

RUN chmod +x /tmp/wait-for-it.sh

RUN envsubst '$RAILS_ROOT' < /tmp/docker.nginx > /etc/nginx/conf.d/default.conf
EXPOSE 80

CMD [ "/tmp/wait-for-it.sh", "appeals-app:3000"]
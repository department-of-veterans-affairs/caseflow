upstream rails_app {
  server 127.0.0.1:3001;
}

server {
  # load balancer => nginx is listening on 3000 => puma 3001
  # https://www.techrepublic.com/article/take-advantage-of-tcp-ip-options-to-optimize-data-transmission/
  # speeds the server's response
  listen 3000 default deferred;
  # match any host name
  # load balancer will control the host name
  server_name _;

  # Access log is targeting app directory to keep all logs in a specific
  # folder for ease of debugging.
  access_log  /opt/efolder-express/src/log/access.log  main;

  # entry point for the static files
  root /opt/efolder-express/src/public;

  # Any URL with /assets should be served by Nginx.

  # Any asset returned by nginx should be gzipped, have cache headers
  location ^~ /assets/ {
    gzip_static on;
    # this will tell the browser to cache it for a very long time
    expires max;
    add_header Cache-Control public;
  }

  # @rails_app - regular name
  # $uri - nginx varible that reprsents the current url
  # if the file is not in public, it will pass the file to rails
  # https:://example.com/assets/image.png - will look at public/assets/image.png
  # https:://example.com/image.png
  try_files $uri @rails_app;

  location @rails_app {
    # These headers will be passed to Puma
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    # Whatever is in the host header, gets passed to Puma in the header => efolder.cf.ds.va.gov
    proxy_set_header Host $http_host;
    #
    proxy_redirect off;
    # Disable disk cache to allow large files to be downloaded.
    # See https://serverfault.com/questions/820597/nginx-does-not-serve-large-files
    proxy_max_temp_file_size 0;
    proxy_pass http://rails_app;
  }

  # Appeals apps have custom 404 and 500s page.
  error_page 404 /404.html;
  error_page 500 502 503 504 /500.html;
  # user => load balancer <=> nginx
  # nginx <=> puma
  keepalive_timeout 10;
}
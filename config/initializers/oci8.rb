# configure timeouts, in seconds, for underlying socket in environments that use Oracle
if defined? OCI8
  OCI8.properties[:tcp_connect_timeout] = 10
  OCI8.properties[:connect_timeout] = 10
  OCI8.properties[:send_timeout] = 10
  OCI8.properties[:recv_timeout] = 20
end

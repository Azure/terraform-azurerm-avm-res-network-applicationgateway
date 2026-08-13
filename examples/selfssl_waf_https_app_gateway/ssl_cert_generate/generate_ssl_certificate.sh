#!/bin/bash
# cd ../certificate.pfx
# Generate a self-signed SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.crt -subj "/C=US/ST=State/L=Singapore/O=AVM /CN=contoso.com"
openssl req -newkey rsa:2048 -nodes -keyout httpd.key -x509 -days 10 -out httpd.crt

# Combine the key and certificate into a PFX file
openssl pkcs12 -export -out certificate.pfx -inkey server.key -in server.crt -passout pass:terraform-avm

ls -lrta certificate.pfx
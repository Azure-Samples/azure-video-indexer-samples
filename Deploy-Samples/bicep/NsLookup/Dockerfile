# Use an official Alpine as a parent image
FROM alpine:latest

# Install dnsutils to get nslookup
RUN apk update && apk add --no-cache bind-tools

# Add a script to run nslookup and keep the container running
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

# Define the command to run the script
CMD ["/usr/local/bin/run.sh"]

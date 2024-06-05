#!/bin/sh

# Check if the DOMAIN and EXPECTED_IP environment variables are set
if [ -z "$DOMAIN" ] || [ -z "$EXPECTED_IP" ]; then
  echo "DOMAIN or EXPECTED_IP environment variable is not set. Exiting..."
  exit 1
fi

# Run nslookup and get the result
actual_ip=$(nslookup $DOMAIN | grep 'Address' | grep -v '#' | awk '{print $2}')

# Compare the actual IP with the expected IP
if [ "$actual_ip" = "$EXPECTED_IP" ]; then
  echo "DNS record matches the expected result."
  exit 0
else
  echo "DNS record does not match the expected result."
  exit 1
fi

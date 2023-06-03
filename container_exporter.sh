#!/bin/bash
#
# container_exporter exposes CPU% and MEM% metrics of all running
# Docker containers to Prometheus
#
#   Copyright (C) 2021 Vincent Falzon
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# Collect the data from all running Docker containers
inspect_ip=$(docker inspect -f '{{.Config.Hostname}} {{.NetworkSettings.Networks.mysql.IPAddress}} ' $(docker ps -q) 2>/dev/null)

# Extract and prepare the metrics
ips=""
while read -r line
do
   read name ip <<< "$line"
   ips="${ips}container_ip{container=\"$name\"} ${ip}\n"
   echo -en $ips
   echo $ip kkk $name
done <<< "$inspect_ip"

# Write the metrics to a temporary file to get the size
tmp=$(mktemp)
echo "# HELP container_ip The IP Address value from docker inspect." > $tmp
echo "# TYPE container_ip text" >> $tmp
echo -en "$ips" >> $tmp

# Display the HTTP header
echo "HTTP/1.1 200 OK"
echo "Date: $(date)"
echo "Content-Length: $(stat -c "%s" $tmp)"
echo "Content-Type: text/plain"
echo "Connection: close"
echo

# Display the metrics
cat $tmp
rm $tmp

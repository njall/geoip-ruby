geoip-ruby
==========

Ruby script to interface with the freegeoip.net web service to return geographical information about an IP address. 

Currently uses command line with IPs as arguments.

Use: ruby geoip.rb <IP address> <IP address> ... <IP address>

There is a limitation of 1000 requests per hour on the freegeoip.net web service so the file COUNT.txt stores the number
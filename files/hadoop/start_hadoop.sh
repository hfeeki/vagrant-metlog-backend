#!/bin/sh
for service in /etc/init.d/hadoop*; do sudo $service stop; done
for service in /etc/init.d/hadoop*; do sudo $service start; done

========================================
Vagrant Metlog back-end test environment
========================================

This vagrant build is to create a CentOS VM that has a full Metlog back end
system (including logstash, ruby-statsd, graphite, pencil, and sentry) for
development and testing purposes.

Installing
==========

**Note**: VirtualBox 4.1.x currently `seems to have a nasty kernel panic issue
with Lion <https://www.virtualbox.org/ticket/9359>`_ , use the second link
provided in 2.1 to install the previous version which is stable in OSX Lion.

1. Install Vagrant: http://downloads.vagrantup.com/tags/v1.0.1

2. Install Virtualbox (**do not install this in OSX Lion**): http://www.virtualbox.org/wiki/Downloads

2. Install Virtualbox (**use this in Lion**): https://www.virtualbox.org/wiki/Download_Old_Builds_4_0

3. Install the box VM used::

       $ vagrant box add centos-60-x86_64 http://dl.dropbox.com/u/1627760/centos-6.0-x86_64.box

4. Run the following::

       $ git clone https://github.com/mozilla-services/vagrant-metlog-backend.git
       $ cd vagrant-metlog-backed
       $ vagrant up


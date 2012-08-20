Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin/' }

# Mozilla packages to install

$baserepo_packages = ['createrepo']

$centos_packages = [
    'python-devel',
    'rpm-devel',
    'rpm-python',
    'rpmdevtools',
    'httpd',
    #'python-simplejson', # we need 2.3 from the sentry packages
    'python-twisted',
    'bitmap-fonts-compat',
]

$moz_packages = [
    'zeromq', # RPMS.mozilla-services
    'whisper', # RPMS.mozilla-services
    'graphite-web', # RPMS.mozilla-services
    'carbon', # RPMS.mozilla-services
    'nginx',    # RPMS.mozilla-services

    #######
    #
    #   Pure python 
    #
    'python26', # RPMS.mozilla-services 
    'python26-setuptools', # RPMS.mozilla-services
                           # Just a metapackage with no files.  Forces
                           # install of 
                           #  python-setuptools  
                           #  rpmlib(PayloadFilesHavePrefix) <= 4.0-1
                           #  rpmlib(CompressedFileNames) <= 3.0.4-1

    'mod_wsgi-3.3-1.el6.x86_64', # RPMS.mozilla
    #'gunicorn', # RPMS.mozilla-services (mozilla compiled)  
                 # We need a 0.14 revision of gunicorn for sentry
                 # This seems crazy.  sentry is just a wsgi app
                 # TODO: send a patch up to sentry to remove
                 # dependency on gunicorn

    'logstash', # RPMS.mozilla-services (JAR files + pattern files). Suggest going straight from spec file.
    'logstash-metlog', # RPMS.mozilla-services 

    #########################
    #
    #   Pure Ruby and pure Python bits
    #   below

    'rubygem-pencil', # RPMS.mozilla-services
    'rubygem-tilt',  # RPMS.mozilla-services
    'rubygem-petef-statsd', # RPMS.mozilla-services
]

$sentry_packages = [
    'Django', 
    'python26-amqplib', 
    'python26-anyjson', 
    'python26-beautifulsoup', 
    'python26-celery', 
    'python26-cssutils', 
    'python26-dateutil', 
    'python26-django-celery', 
    'python26-django-crispy-forms', 
    'python26-django-indexer', 
    'python26-django-paging', 
    'python26-django-picklefield', 
    'python26-django-templatetag-sugar', 
    'python26-gunicorn', 
    'python26-httpagentparser', 
    'python26-importlib', 
    'python26-kombu', 
    'python26-logan', 
    'python26-ordereddict', 
    'python26-pynliner', 
    'python26-pytz', 
    'python26-raven', 
    'python26-sentry', 
    'python26-simplejson', 
    'python26-south', 
    ]

# These come from a signed Fedora 6 EPEL repository
$django_epel = ['django-tagging']

# You better have the real JRE installed - not some weird GCJ
# contraption
$logstash_epel = ['java-1.6.0-sun-1.6.0.22-1jpp.1.el6.x86_64']

# We use Cloudera's CDH3 distribution of Hadoop
$cdh3_packages = [
    'hadoop-0.20',
    'hadoop-0.20-conf-pseudo',
    'hadoop-0.20-datanode',
    'hadoop-0.20-jobtracker',
    'hadoop-0.20-namenode',
    'hadoop-0.20-native',
    'hadoop-0.20-secondarynamenode',
    'hadoop-0.20-tasktracker',
    'hadoop-hbase',
    'hadoop-hive',
    'hadoop-hive-server',
    'hue',
]

$metlog_hive_packages = [
    'metlog-hive',
]

$mysql_packages = ['mysql',
    'mysql-server']

package { 
    $baserepo_packages:
        ensure  => present;

    # From CentOS Base
    $centos_packages:
        ensure => present;
    # From CentOS Base
    'cairo-1.8.8-3.1.el6.x86_64':
        ensure  => present;
    # From CentOS Base
    'pycairo-1.8.6-2.1.el6.x86_64':
        ensure  => present,
        require => [Package["cairo-1.8.8-3.1.el6.x86_64"]];

    $django_epel:
        ensure => present,
        require => [Yumrepo['epel6_rpms']];

    $logstash_epel:
        ensure => present,
        require => [Yumrepo['epel6_rpms']];

    # We want to install the mozilla specific RPMs only *after* all
    # the raw dependencies have been sorted out
    $moz_packages:
        ensure  => present,
        require => [Yumrepo['moz_repo'], Package[$logstash_epel]];


    # Sentry has enough dependencies that we really want a separate
    # repository to manage them
    $sentry_packages:
        ensure  => present,
        require => [Yumrepo['sentry_repo']];

    $cdh3_packages:
        ensure  => present,
        require => [Yumrepo['cdh3_repo']];

    $metlog_hive_packages:
        ensure  => present,
        require => [File['/tmp/test_hdfs_liveliness.sh'], Package[$cdh3_packages], Yumrepo['moz_repo']];

    # Mysql is needed by Apache Hive to back the metadata storage
    $mysql_packages:
        ensure  => present;
}

####
# You can use a local RPM Repo if you really want
#file {
#    'local_repo':
#        ensure => directory,
#        recurse => true,
#        path => "/local_repo",
#        source => "/vagrant/local_repo",
#}
#
#yumrepo {
#    'epel6_rpms':
#        descr       => "Local EPEL RPMs",
#        baseurl     => 'file:///local_repo/epel6/6/x86_64',
#        enabled     => 1,
#        gpgcheck    => 0,
#        require     => File['local_repo'];
#    'moz_repo':
#        descr       => "Mozilla Services Repo",
#        baseurl     => 'file:///local_repo/moz/6/x86_64',
#        enabled     => 1,
#        require     => File['local_repo'],
#        gpgcheck    => 0;
#    'sentry_repo':
#        descr       => "Sentry 4.7.7 RPM Repo",
#        baseurl     => 'file:///local_repo/sentry',
#        require     => File['local_repo'],
#        enabled     => 1,
#        gpgcheck    => 0;
#}
##
####


yumrepo {
    'epel6_rpms':
        descr       => "Local EPEL RPMs",
        baseurl     => 'http://people.mozilla.com/~vng/vagrant_mrepo/epel6/$releasever/$basearch',
        enabled     => 1,
        gpgcheck    => 0;
    'moz_repo':
        descr       => "Mozilla Services Repo",
        baseurl     => 'http://people.mozilla.com/~vng/vagrant_mrepo/moz/$releasever/$basearch',
        enabled     => 1,
        gpgcheck    => 0;
    'sentry_repo':
        descr       => "Sentry 4.7.7 RPM Repo",
        baseurl     => 'http://people.mozilla.com/~vng/vagrant_mrepo/sentry',
        enabled     => 1,
        gpgcheck    => 0;
    'cdh3_repo':
        descr       => "Cloudera 3 Hadoop Repo",
        baseurl     => 'http://people.mozilla.com/~vng/vagrant_mrepo/cdh3/6',
        enabled     => 1,
        gpgcheck    => 0;
}


# Make sure not to install the yum repo until createrepo is ready
Package["createrepo"] -> 
Yumrepo['sentry_repo'] ->
Yumrepo['moz_repo'] ->
Yumrepo['cdh3_repo'] ->
Yumrepo['epel6_rpms']


file {
    # Setup Hive example data
    "/tmp/setup_hive_example.sh":
        ensure => present,
        path   => "/tmp/setup_hive_example.sh",
        source => "/vagrant/files/hadoop/hive/setup_hive_example.sh",
        owner  => "root",
        group  => "root",
        mode   => 775;
    #
    # Hadoop HDFS liveliness script
    "/tmp/test_hdfs_liveliness.sh":
        ensure => present,
        path   => "/tmp/test_hdfs_liveliness.sh",
        source => "/vagrant/files/hadoop/test_hdfs_liveliness.sh",
        owner  => "root",
        group  => "root",
        mode   => 775;
    
    # Hadoop startup script
    "/tmp/start_hadoop.sh":
        require => [Package["hadoop-hive"], Package["hadoop-hbase"], Package["hadoop-hive-server"]],
        ensure => present,
        path   => "/tmp/start_hadoop.sh",
        source => "/vagrant/files/hadoop/start_hadoop.sh",
        owner  => "root",
        group  => "root",
        mode   => 775;

    # MySQLd startup script
    "/tmp/start_mysqld.sh":
        require => [Package["mysql-server"], Package["mysql"]],
        ensure => present,
        path   => "/tmp/start_mysqld.sh",
        source => "/vagrant/files/mysql/start_mysqld.sh",
        owner  => "root",
        group  => "root",
        mode   => 775;
    
    # MySQL security modification script
    "/tmp/init_mysqldb.sql":
        require => [Exec["start_mysqld"]],
        ensure => present,
        path   => "/tmp/init_mysqldb.sql", 
        source => "/vagrant/files/mysql/init_mysqldb.sql",
        owner  => "root",
        group  => "root",
        mode   => 775;

}

# Apache Hive specific mysql configuration
#
file {
    "/etc/hive/conf/hive-site.xml":
        require => [Package["hadoop-hive"]],
        ensure => present,
        path   => "/etc/hive/conf/hive-site.xml",
        source => "/vagrant/files/hadoop/hive/hive-site.xml",
        owner  => "root",
        group  => "root",
        mode   => 644;

    "/etc/hadoop-0.20/conf/mapred-site.xml":
        require => [Package["hadoop-0.20-conf-pseudo"]],
        ensure => present,
        path   => "/etc/hadoop-0.20/conf/mapred-site.xml",
        source => "/vagrant/files/hadoop/mapred-site.xml", 
        owner  => "root",
        group  => "root",
        mode   => 775;

    "/tmp/init_hive.sql":
        require => [Package["mysql"], Package["mysql-server"]],
        ensure => present,
        path   => "/tmp/init_hive.sql",
        source => "/vagrant/files/hadoop/hive/init_hive.sql", 
        owner  => "root",
        group  => "root",
        mode   => 775;

}


####
# MySQL connector installation
file  {
    "/tmp/mysql-jdbc-connector-install.sh":
        require => [Package["mysql"],
                Package["mysql-server"],
                Package["hadoop-hive"],
                Package["hadoop-hive-server"]],
        ensure => present,
        path   => "/tmp/mysql-jdbc-connector-install.sh",
        source => "/vagrant/files/hadoop/mysql-jdbc-connector-install.sh",
        owner  => "root",
        group  => "root",
        mode   => 775;
}

###
# Sentry setup
file {
    "/opt/sentry":
        require => [File["/opt"]],
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 644;

    "/opt/sentry/sentry.db":
        require => [Package["python26-sentry"], File["/opt/sentry"]],
        ensure => present,
        path   => "/opt/sentry/sentry.db",
        source => "/vagrant/files/sentry/sentry.db",
        owner  => "root",
        group  => "root",
        mode   => 755;

    "/opt/sentry/sentry.conf.py":
        ensure => present,
        path   => "/opt/sentry/sentry.conf.py",
        source => "/vagrant/files/sentry/sentry.conf.py",
        owner  => "root",
        group  => "root",
        require => File["/opt/sentry"],
        mode   => 644;
}



## Nginx Setup

file {
    'nginx.conf':
        ensure  => present,
        path    => "/etc/nginx/nginx.conf",
        source  => "/vagrant/files/nginx.conf",
        require => Package["nginx"];
    'default.conf':
        ensure  => absent,
        path    => "/etc/nginx/conf.d/default.conf",
        require => Package["nginx"];
}

service {'nginx':
    ensure      => running,
    enable     => true,
    subscribe   => File["nginx.conf"],
}

## Logstash Setup

file {
    '/etc/logstash.conf':
        ensure  => present,
        path    => "/etc/logstash.conf",
        source  => "/vagrant/files/logstash.conf";
    '/etc/init/logstash.conf':
        ensure  => present,
        path    => "/etc/init/logstash.conf",
        source  => "/vagrant/files/startup/logstash.conf",
        owner   => 'root',
        group   => 'root',
        mode    => 644;
    "/usr/lib64/libzmq.so":
        ensure  => link,
        target  => "/usr/lib64/libzmq.so.1",
        require => Package["zeromq"];
}

# setup the whisperdb
file {
    'whisperdb_init':
        ensure => present,
        path   => "/usr/local/bin/init_whisperdb",
        source => "/vagrant/files/init_whisperdb",
        owner  => "root",
        group  => "root",
        mode   => 755;
}

# Script to open up the firewall
file {
    'firewall_down':
        ensure => present,
        path   => "/usr/local/bin/iptables_flush",
        source => "/vagrant/files/iptables_flush",
        owner  => "root",
        group  => "root",
        mode   => 755;
}

# Graphite/Carbon config files
file {
    '/etc/httpd/conf.d/wsgi.conf':
        ensure => present,
        path   => "/etc/httpd/conf.d/wsgi.conf",
        source => "/vagrant/files/httpd/wsgi.conf",
        owner  => "root",
        group  => "root",
        mode   => 644;
    
    "/opt":
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 644;

    "/opt/graphite":
        require => [File["/opt"]],
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 644;

    "/opt/graphite/conf":
        require => [Package["graphite-web"], File["/opt/graphite"]],
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 644;

    '/opt/graphite/conf/carbon.conf':
        ensure => present,
        path   => "/opt/graphite/conf/carbon.conf",
        source => "/vagrant/files/graphite/carbon.conf",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 644;
    '/opt/graphite/conf/storage-aggregation.conf':
        ensure => present,
        path   => "/opt/graphite/conf/storage-aggregation.conf",
        source => "/vagrant/files/graphite/storage-aggregation.conf",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 644;
    '/opt/graphite/conf/storage-schemas.conf':
        ensure => present,
        path   => "/opt/graphite/conf/storage-schemas.conf",
        source => "/vagrant/files/graphite/storage-schemas.conf",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 644;
    '/opt/graphite/conf/graphite.wsgi':
        ensure => present,
        path   => "/opt/graphite/conf/graphite.wsgi",
        source => "/vagrant/files/graphite/graphite.wsgi",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 755;
}

# Config files for pencil
file {
    '/opt/pencil':
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 644;

    '/opt/pencil/config':
        ensure   => "directory",
        owner   => "root",
        group   => "root",
        require => File["/opt/pencil"],
        mode    => 644;

    '/opt/pencil/config/graphs.yml':
        ensure => present,
        path   => "/opt/pencil/config/graphs.yml",
        source => "/vagrant/files/pencil/graphs.yml",
        owner  => "root",
        group  => "root",
        require => File["/opt/pencil/config"],
        mode   => 755;
    '/opt/pencil/config/dashboards.yml':
        ensure => present,
        path   => "/opt/pencil/config/dashboards.yml",
        source => "/vagrant/files/pencil/dashboards.yml",
        owner  => "root",
        group  => "root",
        require => File["/opt/pencil/config"],
        mode   => 755;
    '/opt/pencil/config/pencil.yml':
        ensure => present,
        path   => "/opt/pencil/config/pencil.yml",
        source => "/vagrant/files/pencil/pencil.yml",
        owner  => "root",
        group  => "root",
        require => File["/opt/pencil/config"],
        mode   => 755;
}


## startup scripts for sentry, statsd, carbon and pencil
file {
    '/etc/init.d/statsd':
        ensure  => present,
        path    => "/etc/init.d/statsd",
        source  => "/vagrant/files/startup/statsd",
        owner   => 'root',
        group   => 'root',
        mode    => 755,
        force   => true;

    '/etc/init/sentry.conf':
        ensure  => present,
        path    => "/etc/init/sentry.conf",
        source  => "/vagrant/files/startup/sentry.conf",
        owner   => 'root',
        group   => 'root',
        mode    => 755,
        force   => true;

    '/etc/init/carbon.conf':
        ensure  => present,
        path    => "/etc/init/carbon.conf",
        source  => "/vagrant/files/startup/carbon.conf",
        owner   => 'root',
        group   => 'root',
        mode    => 755,
        force   => true;
    '/etc/init/pencil.conf':
        ensure  => present,
        path    => "/etc/init/pencil.conf",
        source  => "/vagrant/files/startup/pencil.conf",
        owner   => 'root',
        group   => 'root',
        mode    => 755,
        force   => true;
}

# Sample HDFS data 
file {
    '/var/log/aitc':
        ensure => "directory",
        owner  => "root",
        group  => "root",
        mode   => 775;

    '/var/log/aitc/metrics_hdfs.log':
        ensure  => present,
        path    => "/var/log/aitc/metrics_hdfs.log",
        source  => "/vagrant/files/var/log/aitc/metrics_hdfs.log",
        owner   => 'root',
        group   => 'root',
        mode    => 775,
        force   => true;
}

exec {
    'update_init':
        command => "/sbin/initctl reload-configuration",
        subscribe   => File["/etc/init/logstash.conf"],
        require => Package["logstash-metlog"];

    'start_logstash':
        command => "/sbin/initctl start logstash",
        unless  => "/sbin/initctl status logstash | grep -w running";

    'start_pencil':
        command     => "/sbin/initctl start pencil",
        unless  => "/sbin/initctl status pencil | grep -w running",
        require     => [File["/etc/init/pencil.conf"], 
                        File["/opt/pencil/config/pencil.yml"],
                        File["/opt/pencil/config/graphs.yml"],
                        File["/opt/pencil/config/dashboards.yml"]];
    'start_sentry':
        command     => "/sbin/initctl start sentry",
        unless      => "/sbin/initctl status sentry | grep -w running",
        require     => [File["/etc/init/sentry.conf"], Package['python26-sentry'],

    # This is crazy.  The sentry RPM needs to be rebuilt to properly
    # specify RPM dependencies
        Package["Django"], 
        Package["python26-amqplib"], 
        Package["python26-anyjson"], 
        Package["python26-beautifulsoup"], 
        Package["python26-celery"], 
        Package["python26-cssutils"], 
        Package["python26-dateutil"], 
        Package["python26-django-celery"], 
        Package["python26-django-crispy-forms"], 
        Package["python26-django-indexer"], 
        Package["python26-django-paging"], 
        Package["python26-django-picklefield"], 
        Package["python26-django-templatetag-sugar"], 
        Package["python26-gunicorn"], 
        Package["python26-httpagentparser"], 
        Package["python26-importlib"], 
        Package["python26-kombu"], 
        Package["python26-logan"], 
        Package["python26-ordereddict"], 
        Package["python26-pynliner"], 
        Package["python26-pytz"], 
        Package["python26-raven"], 
        Package["python26-simplejson"], 
        Package["python26-south"], 


];

    'statsd_up':
        command     => "/sbin/service statsd start",
        require     => File["/etc/init.d/statsd"];
    'start_carbon':
        command     => "/sbin/initctl start carbon",
        unless      => "/sbin/initctl status carbon| grep -w running",
        require     => File["/etc/init/carbon.conf"];
    'iptables_down':
        command     => "/usr/local/bin/iptables_flush",
        require     => File["firewall_down"];
    'init_whisperdb':
        command     => "/usr/local/bin/init_whisperdb",
        require     => File["whisperdb_init"];
    'restart_apache':
        command     => "/sbin/service httpd restart",
        require     => [File["/etc/httpd/conf.d/wsgi.conf"], File["/opt/graphite/conf/graphite.wsgi"], Exec["iptables_down"]];

    'install_mysql_jdbc_connector':
        command     => "/tmp/mysql-jdbc-connector-install.sh",
        require     => [File["/tmp/mysql-jdbc-connector-install.sh"]],
        onlyif      => "test ! -f /usr/lib/hive/lib/mysql-connector-java-5.1.15-bin.jar";

    'restart_hadoop':
        command     => "sh /tmp/start_hadoop.sh",
        require     => [File["/tmp/start_hadoop.sh"], File["/etc/hadoop-0.20/conf/mapred-site.xml"], Exec["install_mysql_jdbc_connector"]];

    'start_hue':
        command     => "sh /etc/init.d/hue start";

    'start_mysqld':
        command     => "/tmp/start_mysqld.sh",
        require     => [File["/tmp/start_mysqld.sh"]];

    'init_mysqld':
        command     => "cat /tmp/init_mysqldb.sql | mysql -u root",
        require     => [Exec["start_mysqld"], File["/tmp/init_mysqldb.sql"]],
        unless      => "/usr/bin/mysql --user=mydbadmin --password=mypass -e \"show databases\"";

    'init_hive':
        require     => [File["/tmp/init_hive.sql"], Exec["init_mysqld"]],
        command     => "cat /tmp/init_hive.sql | mysql --user=mydbadmin --password=mypass;",
        unless => "/usr/bin/mysql --user=mydbadmin --password=mypass -e \"use metastore;\"";

    'install_metlog_hive':
        require     => [Package['metlog-hive'], Exec["init_hive"], File['/tmp/test_hdfs_liveliness.sh']],
        command     => "sh /tmp/test_hdfs_liveliness.sh; sudo -u vagrant /usr/bin/hadoop dfs -mkdir /metlog/lib/; sudo -u vagrant /usr/bin/hadoop dfs -put /opt/metlog/hadoop/hive/MetlogHive.jar /metlog/lib/MetlogHive.jar",
        unless => "/usr/bin/hadoop dfs -ls /metlog/lib/MetlogHive.jar";

    'setup_hive_example':
        require     => [Package["hadoop-hive-server"], Exec["install_metlog_hive"], File['/tmp/setup_hive_example.sh'], Exec["restart_hadoop"]],
        command     => "sh /tmp/test_hdfs_liveliness.sh; chmod -R 777 /var/lib/hive; sh /tmp/setup_hive_example.sh",
        unless => "sudo -u vagrant /usr/bin/hadoop dfs -ls /var/log/aitc/metrics_hdfs.log";

}


Package["zeromq"] ->
Package["logstash"] ->
Package["logstash-metlog"]

File["/etc/logstash.conf"] ->
File["/etc/init/logstash.conf"] ->
Exec["start_logstash"]

File["/etc/httpd/conf.d/wsgi.conf"] ->
File["/opt/graphite/conf/carbon.conf"] ->
File["/opt/graphite/conf/graphite.wsgi"] ->
File["/etc/init.d/statsd"] ->
File["/etc/init/carbon.conf"] ->
Exec["init_whisperdb"] ->
File["/etc/init/pencil.conf"] ->
Exec["start_pencil"]

Exec["iptables_down"] ->
Exec["restart_apache"] ->
Exec["start_sentry"]

Exec["init_hive"] ->
Exec["restart_hadoop"] ->
Exec["install_metlog_hive"]

File["/etc/hive/conf/hive-site.xml"] ->
Exec["restart_hadoop"] ->
Exec['setup_hive_example'] ->
Exec['start_hue']


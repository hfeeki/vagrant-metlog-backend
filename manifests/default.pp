Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin/' }

# Mozilla packages to install

$baserepo_packages = ['createrepo']

$centos_packages = [
    'python-devel',
    'rpm-devel',
    'rpm-python',
    'rpmdevtools',
    'httpd',
    'python-simplejson',
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
    'gunicorn', # RPMS.mozilla-services (mozilla compiled)
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

# These come from a signed Fedora 6 EPEL repository
$django_epel = ['Django','django-tagging']

# You better have the real JRE installed - not some weird GCJ
# contraption
$logstash_epel = ['java-1.6.0-sun-1.6.0.22-1jpp.1.el6.x86_64']

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
        require => [Yumrepo['local-rpms'], Package[$logstash_epel]];

}

## Local RPM Repo

yumrepo {
    'epel6_rpms':
        descr       => "Local EPEL RPMs",
        baseurl     => 'http://people.mozilla.com/~vng/vagrant_mrepo/epel6/$releasever/$basearch',
        enabled     => 1,
        gpgcheck    => 0;
    'local-rpms':
        descr       => "Mozilla Services Repo",
        baseurl     => 'http://people.mozilla.com/~vng/vagrant_mrepo/moz/$releasever/$basearch',
        enabled     => 1,
        gpgcheck    => 0;
}


exec {
    'update_repo':
       command     => "createrepo /local_repo/moz";
    'update_epel6_repo':
       command     => "createrepo /local_repo/epel6";
    'clear_metadata':
        command     => "yum clean metadata",
        subscribe   => [File["/local_repo"], 
                       File["/local_repo/moz"],
                       File["/local_repo/epel6"]];
}


# Make sure not to install the yum repo until its completely ready
Package["createrepo"] -> 
File["/local_repo"] -> 
File["/local_repo/moz"] -> 
File["/local_repo/epel6"] -> 
Exec["update_repo"] -> 
Exec["update_epel6_repo"] -> 
Yumrepo['local-rpms'] ->
Yumrepo['epel6_rpms']

## Nginx Setup

file {
    '/local_repo':
        ensure  => directory,
        recurse => true,
        path    => "/local_repo",
        source  => "/vagrant/local_repo";
    '/local_repo/moz':
        ensure  => directory,
        recurse => true,
        path    => "/local_repo/moz",
        source  => "/vagrant/local_repo/moz",
        require => File["/local_repo"];
    '/local_repo/epel6':
        ensure  => directory,
        recurse => true,
        path    => "/local_repo/epel6",
        source  => "/vagrant/local_repo/epel6";
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
    'logstash.conf':
        ensure  => present,
        path    => "/etc/logstash.conf",
        source  => "/vagrant/files/logstash.conf";
    'logstash_init':
        ensure  => present,
        path    => "/etc/init/logstash.conf",
        source  => "/vagrant/files/logstash.init.conf",
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
    'wsgi_conf':
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

    'carbon_conf':
        ensure => present,
        path   => "/opt/graphite/conf/carbon.conf",
        source => "/vagrant/files/graphite/carbon.conf",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 644;
    'storageaggregation_conf':
        ensure => present,
        path   => "/opt/graphite/conf/storage-aggregation.conf",
        source => "/vagrant/files/graphite/storage-aggregation.conf",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 644;
    'storageschemas_conf':
        ensure => present,
        path   => "/opt/graphite/conf/storage-schemas.conf",
        source => "/vagrant/files/graphite/storage-schemas.conf",
        owner  => "root",
        group  => "root",
        require => File["/opt/graphite/conf"],
        mode   => 644;
    'graphite_wsgi':
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


## startup scripts for statsd, carbon and pencil
file {
    'statsd_init':
        ensure  => present,
        path    => "/etc/init.d/statsd",
        source  => "/vagrant/files/startup/statsd",
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

exec {
    'update_init':
        command => "/sbin/initctl reload-configuration",
        subscribe   => File["logstash_init"],
        require => Package["logstash-metlog"];

    'start_logstash':
        command => "/sbin/initctl start logstash",
        unless  => "/sbin/initctl status logstash | grep -w running";

    'reload_pencil':
        command     => "/sbin/initctl restart pencil",
        subscribe   => [File["/opt/pencil/config/graphs.yml"],
                        File["/opt/pencil/config/dashboards.yml"],
                        File["/opt/pencil/config/pencil.yml"]],
        require     => Package["rubygem-pencil"],
        refreshonly => true;

    'reload_logstash':
        command     => "/sbin/initctl restart logstash",
        subscribe   => File["logstash.conf"],
        require     => Package["logstash"],
        refreshonly => true;
    'pencil_down':
        command     => "/sbin/initctl stop pencil",
        require     => [Package["rubygem-pencil"],
                        Package["rubygem-tilt"],
                        File["/etc/init/pencil.conf"], 
                        File["/opt/pencil/config/pencil.yml"],
                        File["/opt/pencil/config/graphs.yml"],
                        File["/opt/pencil/config/dashboards.yml"]];
    'pencil_up':
        command     => "/sbin/initctl start pencil",
        require     => [File["/etc/init/pencil.conf"], 
                        File["/opt/pencil/config/pencil.yml"],
                        File["/opt/pencil/config/graphs.yml"],
                        File["/opt/pencil/config/dashboards.yml"]];
    'statsd_up':
        command     => "/sbin/service statsd start",
        require     => File["statsd_init"];
    'carbon_up':
        command     => "/sbin/initctl start carbon",
        require     => File["/etc/init/carbon.conf"];
    'iptables_down':
        command     => "/usr/local/bin/iptables_flush",
        require     => File["firewall_down"];
    'init_whisperdb':
        command     => "/usr/local/bin/init_whisperdb",
        require     => File["whisperdb_init"];
    'restart_apache':
        command     => "/sbin/service httpd restart",
        require     => [File["wsgi_conf"], File["graphite_wsgi"], Exec["iptables_down"]];
}


Package["zeromq"] ->
Package["logstash"] ->
Package["logstash-metlog"] ->
File["wsgi_conf"] ->
File["carbon_conf"] ->
File["graphite_wsgi"] ->
File["logstash.conf"] ->
File["logstash_init"] ->
Exec["start_logstash"] ->
Exec["init_whisperdb"] ->
File["/etc/init/pencil.conf"] ->
File["statsd_init"] ->
File["/etc/init/carbon.conf"] ->
Exec["iptables_down"] ->
Exec["restart_apache"] ->
Exec["pencil_up"]

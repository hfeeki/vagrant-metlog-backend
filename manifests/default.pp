Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin/' }

# Mozilla packages to install
$moz_packages = ['createrepo','nginx','gunicorn','logstash','python26','python26-setuptools','python-devel','rubygem-petef-statsd','rpm-devel','rpm-python','rpmdevtools','zeromq','whisper','rubygem-pencil','graphite-web','carbon','django-tagging','httpd','python-twisted','mod_wsgi-3.3-1.el6.x86_64','bitmap-fonts-compat'] 

yumrepo {
    'packages-all':
        descr       => "CentOS All",
        baseurl     => 'http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.all',
        enabled     => 1,
        gpgcheck    => 0;
    'mozilla-services':
        descr       => "Mozilla Services Repo",
        baseurl     => 'http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.mozilla-services',
        enabled     => 1,
        gpgcheck    => 0;
    'packages-mozilla':
        descr       => "Mozilla Packages Repo",
        baseurl     => 'http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.mozilla',
        enabled     => 1,
        gpgcheck    => 0;
    'packages-centos-base':
        descr       => "CentOS Base",
        baseurl     => 'http://mrepo.mozilla.org/mrepo/$releasever-$basearch/RPMS.centos-base',
        enabled     => 1,
        gpgcheck    => 0;
}

package { 
    $moz_packages:
        ensure  => present,
        require => [Host["mrepo"], 
                    Yumrepo['packages-all'],
                    Yumrepo['mozilla-services'],
                    Yumrepo['packages-mozilla'],
                    Yumrepo['packages-centos-base']];
    'cairo-1.8.8-3.1.el6.x86_64':
        ensure  => present,
        require => [Host["mrepo"], 
                    Yumrepo['packages-all']];
    'pycairo-1.8.6-2.1.el6.x86_64':
        ensure  => present,
        require => [Host["mrepo"], 
                    Package["cairo-1.8.8-3.1.el6.x86_64"],
                    Yumrepo['packages-all']];

}

# From remote, one of the mrepo's doesn't work, so we hardcode in the
# one that
# does work reliably over the VPN
host { 'mrepo':
    ensure => present,
    name => "mrepo.mozilla.org",
    ip => "63.245.217.47",
}

## Local RPM Repo

yumrepo {
    'local-rpms':
        descr       => "Local RPMs",
        baseurl     => 'file:///local_repo/',
        enabled     => 1,
        gpgcheck    => 0,
}

file {
    'local_repo':
        ensure  => directory,
        recurse => true,
        path    => "/local_repo",
        source  => "/vagrant/local_repo",
}

exec {
    'update_repo':
        command     => "createrepo /local_repo",
        subscribe   =>  File["local_repo"];
    'clear_metadata':
        command     => "yum clean metadata",
        subscribe   => File["local_repo"];
}


# Make sure not to install the yum repo until its completely ready
Package["createrepo"] -> File["local_repo"] -> Exec["update_repo"] -> Yumrepo['local-rpms']

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
    'logstash.conf':
        ensure  => present,
        path    => "/etc/logstash.conf",
        source  => "/vagrant/files/logstash.conf";
    'logstash_plugins':
        ensure  => directory,
        path    => "/opt/logstash/plugins",
        source  => "/vagrant/files/plugins",
        recurse => true,
        force   => true;
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
    
    "/opt/graphite/conf":
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

    'pencil_graphs_yml':
        ensure => present,
        path   => "/opt/pencil/config/graphs.yml",
        source => "/vagrant/files/pencil/graphs.yml",
        owner  => "root",
        group  => "root",
        require => File["/opt/pencil/config"],
        mode   => 755;
    'pencil_dashboards_yml':
        ensure => present,
        path   => "/opt/pencil/config/dashboards.yml",
        source => "/vagrant/files/pencil/dashboards.yml",
        owner  => "root",
        group  => "root",
        require => File["/opt/pencil/config"],
        mode   => 755;
    'pencil_pencil_yml':
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
    'carbon_init':
        ensure  => present,
        path    => "/etc/init.d/carbon",
        source  => "/vagrant/files/startup/carbon",
        owner   => 'root',
        group   => 'root',
        mode    => 755,
        force   => true;
    'pencil_init':
        ensure  => present,
        path    => "/etc/init.d/pencil",
        source  => "/vagrant/files/startup/pencil",
        owner   => 'root',
        group   => 'root',
        mode    => 755,
        force   => true;
}

exec {
    'update_init':
        command => "/sbin/initctl reload-configuration",
        subscribe   => File["logstash_init"],
        require => File["logstash_plugins"];
    'start_logstash':
        command => "/sbin/initctl start logstash",
        unless  => "/sbin/initctl status logstash | grep -w running";
    'reload_logstash':
        command     => "/sbin/initctl restart logstash",
        subscribe   => File["logstash.conf"],
        refreshonly => true;
    'pencil_down':
        command     => "/sbin/service pencil stop",
        require     => [File["pencil_init"], 
                        File["pencil_pencil_yml"],
                        File["pencil_graphs_yml"],
                        File["pencil_dashboards_yml"]];
    'pencil_up':
        command     => "/sbin/service pencil start",
        require     => [File["pencil_init"], 
                        File["pencil_pencil_yml"],
                        File["pencil_graphs_yml"],
                        File["pencil_dashboards_yml"]];
    'statsd_up':
        command     => "/sbin/service statsd start",
        require     => File["statsd_init"];
    'carbon_up':
        command     => "/sbin/service carbon start",
        require     => File["statsd_init"];
    'iptables_down':
        command     => "/usr/local/bin/iptables_flush",
        require     => File["firewall_down"];
    'init_whisperdb':
        command     => "/usr/local/bin/init_whisperdb",
        require     => File["whisperdb_init"];
    'restart_apache':
        command     => "/sbin/service httpd restart",
        require     => [File["wsgi_conf"], Exec["iptables_down"]];
}


Host["mrepo"] ->
Package["zeromq"] ->
Package["logstash"] ->
File["wsgi_conf"] ->
File["carbon_conf"] ->
File["graphite_wsgi"] ->
File["logstash.conf"] ->
File["logstash_init"] ->
File["logstash_plugins"] ->
Exec["start_logstash"] ->
Exec["init_whisperdb"] ->
File["pencil_init"] ->
File["statsd_init"] ->
File["carbon_init"] ->
Exec["pencil_down"] ->
Exec["pencil_up"] ->
Exec["iptables_down"] ->
Exec["restart_apache"]

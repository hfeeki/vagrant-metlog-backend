Vagrant::Config.run do |config|
  config.vm.box = "centos-60-x86_64"
  config.vm.network :hostonly, "192.168.20.2"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path   = "modules"
  end
  config.vm.customize ["modifyvm", :id, "--memory", 2048] 
end

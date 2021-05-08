Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"
  config.vm.box = "ubuntu/xenial64"

  config.vm.synced_folder "./config", "/home/vagrant/config"

  config.vm.define "db-server" do |db|
      db.vm.network "forwarded_port", guest: 3306, host: 3306
      db.vm.provision "shell", path: "bootstrap.sh"
  end
end
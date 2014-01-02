package "openssl"
package "build-essential"
package "git-core"
package "sqlite3"
package "libsqlite3-dev"
package "python-software-properties"
package "openjdk-7-jre"
package "nodejs"
package "imagemagick"
package "graphicsmagick-libmagick-dev-compat"

user node[:user][:name] do
  password node[:user][:password]
  group node[:user][:group]
  home "/home/#{node[:user][:name]}"
  supports manage_home: true
  shell "/bin/bash"
end

template "/home/#{node[:user][:name]}.bashrc" do
  source "bashrc.erb"
  owner node[:user][:name]
end

script "install_fits" do
  interpreter "bash"
  cwd "/opt"
  user "root"
  code <<-EOH
  wget https://fits.googlecode.com/files/fits-0.6.2.zip
  unzip fits-0.6.2.zip
  cd fits-0.6.2
  chmod +x fits.sh
  EOH

  not_if { ::File.executable?("/opt/fits-0.6.2/fits.sh") }
end

script "install_redis" do
  interpreter "bash"
  cwd "/usr/local/src"
  user "root"
  code <<-EOH
  wget http://download.redis.io/releases/redis-2.8.3.tar.gz
  tar -zxf redis-2.8.3.tar.gz
  cd redis-2.8.3
  sudo make
  sudo make install
  EOH

  not_if { ::File.exists?("/usr/local/bin/redis-server") }
end

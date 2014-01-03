#
# Cookbook Name:: fedora-commons
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

script "download_fedora" do
  interpreter "bash"
  cwd "/home/#{node[:user][:name]}"
  user node[:user][:name]
  code <<-EOH
  wget http://downloads.sourceforge.net/fedora-commons/fcrepo-installer-3.7.0.jar
  EOH

  not_if { ::File.exists?("/home/#{node[:user][:name]}/fcrepo-installer-3.7.0.jar") }
end

script "update_environment" do
  interpreter "bash"
  cwd "/etc"
  user "root"
  code <<-EOH
  echo $JAVA_HOME >> temp.log
  echo $FEDORA_HOME >> temp.log
  echo $CATALINA_HOME >> temp.log

  if ! grep -Fq "JAVA_HOME=/usr" /etc/environment; then
    echo "JAVA_HOME=/usr" >> /etc/environment
  fi
  if ! grep -Fq "FEDORA_HOME=/usr/local/fedora" /etc/environment; then
    echo "FEDORA_HOME=/usr/local/fedora" >> /etc/environment
  fi
  if ! grep -Fq "CATALINA_HOME=/usr/local/fedora/tomcat" /etc/environment; then
    echo "CATALINA_HOME=/usr/local/fedora/tomcat" >> /etc/environment
  fi
  EOH
end

include_recipe "database::mysql"

mysql_connection_info = {
  :host     => node['fedora-commons'][:database_host],
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

mysql_database node['fedora-commons'][:database_name] do
  connection   mysql_connection_info
  action       :create
end

mysql_database_user node['fedora-commons'][:database_username] do
  connection    mysql_connection_info
  password      node['fedora-commons'][:database_password]
  database_name node['fedora-commons'][:database_name]
  host          'localhost'
  privileges    [:all]
  action        :grant
end

mysql_database_user node['fedora-commons'][:database_username] do
  connection    mysql_connection_info
  password      node['fedora-commons'][:database_password]
  database_name node['fedora-commons'][:database_name]
  host          '%'
  privileges    [:all]
  action        :grant
end

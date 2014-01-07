#
# Cookbook Name:: fedora-commons
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

script "update_environment" do
  interpreter "bash"
  cwd "/etc"
  user "root"
  code <<-EOH
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
  action        :create
end

mysql_database_user node['fedora-commons'][:database_username] do
  connection    mysql_connection_info
  password      node['fedora-commons'][:database_password]
  action        :create
end

mysql_database_user node['fedora-commons'][:database_username] do
  connection    mysql_connection_info
  password      node['fedora-commons'][:database_password]
  database_name node['fedora-commons'][:database_name]
  privileges    [:all]
  action        :grant
end

mysql_database_user node['fedora-commons'][:database_username] do
  connection    mysql_connection_info
  password      node['fedora-commons'][:database_password]
  database_name node['fedora-commons'][:database_name]
  privileges    [:all]
  action        :grant
end

template "/home/#{node[:user][:name]}/install.properties" do
  source "install.properties.erb"
  owner node[:user][:name]
  group node[:user][:name]
end

directory "#{node['fedora-commons'][:fedora_home]}" do
  owner node[:user][:name]
  group node[:user][:name]
  action :create
end

execute "download_fedora" do
  cwd "/home/#{node[:user][:name]}"
  user node[:user][:name]
  group node[:user][:name]
  command "wget http://sourceforge.net/projects/fedora-commons/files/fedora/#{node['fedora-commons'][:version]}/fcrepo-installer-#{node['fedora-commons'][:version]}.jar"

  not_if { ::File.exists?("/home/#{node[:user][:name]}/fcrepo-installer-#{node['fedora-commons'][:version]}.jar") }
end

execute "install_fedora" do
  user node[:user][:name]
  group node[:user][:name]
  cwd "/home/#{node[:user][:name]}"
  command "java -jar fcrepo-installer-#{node['fedora-commons'][:version]}.jar install.properties"

  not_if { ::File.exists?("#{node['fedora-commons'][:catalina_home]}") }
end

execute "download_solr" do
  cwd "/home/#{node[:user][:name]}"
  user node[:user][:name]
  group node[:user][:name]
  command "wget http://psg.mtu.edu/pub/apache/lucene/solr/#{node[:solr][:version]}/solr-#{node[:solr][:version]}.tgz"

  not_if { ::File.exists?("/home/#{node[:user][:name]}/solr-#{node[:solr][:version]}.tgz") }
end

execute "extract_solr" do
  cwd "/home/#{node[:user][:name]}"
  user node[:user][:name]
  group node[:user][:name]
  command "tar -zxf solr-#{node[:solr][:version]}.tgz"

  not_if { ::File.exists?("/home/#{node[:user][:name]}/solr-#{node[:solr][:version]}") }
end

require 'etc'
uid = Etc.getpwnam(node[:user][:name]).uid

script "install_solr" do
  interpreter "bash"
  cwd "/home/#{node[:user][:name]}"
  user 'root'
  code <<-EOH
  cp -pr solr-#{node[:solr][:version]}/example/solr #{node[:solr][:home]}
  chown -R #{node[:user][:name]}:#{node[:user][:name]} #{node[:solr][:home]}
  EOH

  not_if { ::File.exists?("#{node[:solr][:home]}") }
  #not_if { ::File.stat(node[:solr][:home]).uid == uid }
end

script "make_solr_app" do
  interpreter "bash"
  cwd "/home/#{node[:user][:name]}"
  user node[:user][:name]
  group node[:user][:name]
  code <<-EOH
  tar -zxf solr-#{node[:solr][:version]}.tgz
  cp -pr solr-#{node[:solr][:version]}/dist/solr-#{node[:solr][:version]}.war #{node[:solr][:home]}/solr.war
  cp -pr solr-#{node[:solr][:version]}/example/lib/ext/* #{node['fedora-commons'][:catalina_home]}/lib
  cp -pr solr-#{node[:solr][:version]}/example/resources/log4j.properties #{node['fedora-commons'][:catalina_home]}/lib
  EOH

  not_if { ::File.directory?("/#{node[:solr][:home]}/#{node[:solr][:home]}/solr.war") }
end

directory "#{node[:solr][:dataDir]}" do
  owner node[:user][:name]
  group node[:user][:name]
  action :create
end

directory "#{node[:solr][:dataDir]}/data" do
  owner node[:user][:name]
  group node[:user][:name]
  action :create
end

directory "#{node[:solr][:home]}/conf" do
  owner node[:user][:name]
  group node[:user][:name]
  action :create
end

template "#{node[:solr][:home]}/conf/solrconfig.xml" do
  source "solrconfig.xml.erb"
  owner node[:user][:name]
  group node[:user][:name]
end

template "#{node['fedora-commons'][:catalina_home]}/conf/Catalina/localhost/bl_solr.xml" do
  source "bl_solr.xml.erb"
  owner node[:user][:name]
  group node[:user][:name]
end


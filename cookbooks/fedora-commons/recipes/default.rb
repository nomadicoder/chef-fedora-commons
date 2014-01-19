#
# Cookbook Name:: fedora-commons
# Recipe:: default
#
# Copyright 2014, Chinese Historical Society of Southern California
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

script "update_environment" do
  interpreter "bash"
  cwd "/etc"
  user "root"
  code <<-EOH
  if ! grep -Fq "JAVA_HOME=#{node['fedora-commons'][:java_home]}" /etc/environment; then
    echo "JAVA_HOME=#{node['fedora-commons'][:java_home]}" >> /etc/environment
  fi
  if ! grep -Fq "FEDORA_HOME=#{node['fedora-commons'][:fedora_home]}" /etc/environment; then
    echo "FEDORA_HOME=#{node['fedora-commons'][:fedora_home]}" >> /etc/environment
  fi
  if ! grep -Fq "CATALINA_HOME=#{node['fedora-commons'][:catalina_home]}" /etc/environment; then
    echo "CATALINA_HOME=#{node['fedora-commons'][:catalina_home]}" >> /etc/environment
  fi
  if ! grep -Fq "RAILS_ENV=#{node['fedora-commons'][:rails_env]}" /etc/environment; then
    echo "RAILS_HOME=#{node['fedora-commons'][:rails_env]}" >> /etc/environment
  fi
  EOH
end

#
# Set up MySQL Database
#

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

#
# Set up fedora-commons
#

directory "#{node['fedora-commons'][:installDir]}" do
  owner  node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  action :create
end

directory "#{node['fedora-commons'][:fedora_home]}" do
  owner  node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  action :create
end

execute "download_fedora" do
  cwd    "#{node['fedora-commons'][:installDir]}"
  user   node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  command "wget http://sourceforge.net/projects/fedora-commons/files/fedora/#{node['fedora-commons'][:version]}/fcrepo-installer-#{node['fedora-commons'][:version]}.jar"

  not_if { ::File.exists?("#{node['fedora-commons'][:installDir]}/fcrepo-installer-#{node['fedora-commons'][:version]}.jar") }
end

template "#{node['fedora-commons'][:installDir]}/install.properties" do
  source "install.properties.erb"
  owner  node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
end

execute "install_fedora" do
  cwd    "#{node['fedora-commons'][:installDir]}"
  user   node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  command "java -jar fcrepo-installer-#{node['fedora-commons'][:version]}.jar install.properties"

  not_if { ::File.exists?("#{node['fedora-commons'][:catalina_home]}/conf/Catalina/localhost/fedora.xml") }
end

#
# Work around error creating fcrepoRebuildStatus table
#

execute "work_aorund_table_creation_bug" do
  cwd    "#{node['fedora-commons'][:installDir]}"
  user   node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  command <<-EOH
    mysql -u #{node['fedora-commons'][:database_username]} -p#{node['fedora-commons'][:database_password]} #{node['fedora-commons'][:database_name]} -e \
    "CREATE TABLE IF NOT EXISTS fcrepoRebuildStatus ( rebuildDate bigint NOT NULL, complete boolean NOT NULL, UNIQUE KEY rebuildDate (rebuildDate), PRIMARY KEY rebuildDate (rebuildDate));"
  EOH
end

#
# Install Solr
#

execute "download_solr" do
  cwd    "#{node['fedora-commons'][:installDir]}"
  user   node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  command "wget http://psg.mtu.edu/pub/apache/lucene/solr/#{node[:solr][:version]}/solr-#{node[:solr][:version]}.tgz"

  not_if { ::File.exists?("#{node['fedora-commons'][:installDir]}/solr-#{node[:solr][:version]}.tgz") }
end

execute "extract_solr" do
  cwd    "#{node['fedora-commons'][:installDir]}"
  user   node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  command "tar -zxf solr-#{node[:solr][:version]}.tgz"

  not_if { ::File.exists?("#{node['fedora-commons'][:installDir]}/solr-#{node[:solr][:version]}") }
end

directory "#{node[:solr][:home]}" do
  recursive true
  owner  node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  action :create
end

directory "#{node[:solr][:home]}/lib" do
  recursive true
  owner  node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
  action :create
end

execute "make_solr_app" do
  cwd   "#{node['fedora-commons'][:installDir]}"
  user  node['fedora-commons'][:tomcat_user]
  group node['fedora-commons'][:tomcat_user]
  command "cp -pr solr-#{node[:solr][:version]}/dist/solr-#{node[:solr][:version]}.war #{node[:solr][:home]}/solr.war"

  not_if { ::File.exists?("#{node[:solr][:home]}/#{node[:solr][:home]}/solr.war") }
end

execute "copy_java_archives" do
  cwd   "#{node['fedora-commons'][:installDir]}"
  user  node['fedora-commons'][:tomcat_user]
  group node['fedora-commons'][:tomcat_user]
  command "cp -pr solr-#{node[:solr][:version]}/dist/*.jar #{node[:solr][:home]}/lib"

  not_if { ::File.directory?("#{node[:solr][:home]}/#{node[:solr][:home]}/lib/solr-core-4.6.0.jar") }
end

execute "copy_solr_contrib" do
  cwd   "#{node['fedora-commons'][:installDir]}"
  user  node['fedora-commons'][:tomcat_user]
  group node['fedora-commons'][:tomcat_user]
  command "cp -pr solr-#{node[:solr][:version]}/contrib #{node[:solr][:home]}/lib"

  not_if { ::File.directory?("#{node[:solr][:home]}/#{node[:solr][:home]}/lib/velocity") }
end

execute "copy_sample_collection1_dir_to_production" do
  cwd   "#{node['fedora-commons'][:installDir]}"
  user  node['fedora-commons'][:tomcat_user]
  group node['fedora-commons'][:tomcat_user]
  command "cp -pr solr-#{node[:solr][:version]}/example/solr/collection1 #{node[:solr][:home]}/collection1"

  not_if { ::File.directory?("#{node[:solr][:home]}/collection1") }
end

execute "copy_english_stopwords_up_a_level" do
  cwd   "#{node['fedora-commons'][:installDir]}"
  user  node['fedora-commons'][:tomcat_user]
  group node['fedora-commons'][:tomcat_user]
  command "cp -pr #{node[:solr][:home]}/collection1/conf/lang/stopwords_en.txt #{node[:solr][:home]}/collection1/conf"

  not_if { ::File.exists?("#{node[:solr][:home]}/collection1/conf/stopwords_en.txt") }
end

template "#{node[:solr][:home]}/#{node[:solr][:hydra_name]}.xml" do
  source "bl_solr.xml.erb"
  owner  node['fedora-commons'][:tomcat_user]
  group  node['fedora-commons'][:tomcat_user]
end

execute "link_tomcat_to_project_xml_file" do
  cwd   "#{node['fedora-commons'][:installDir]}"
  user  node['fedora-commons'][:tomcat_user]
  group node['fedora-commons'][:tomcat_user]
  command "ln -s #{node[:solr][:home]}/#{node[:solr][:hydra_name]}.xml /etc/tomcat7/Catalina/localhost/#{node[:solr][:hydra_name]}.xml"

  not_if { ::File.symlink?("/etc/tomcat7/Catalina/localhost/#{node[:solr][:hydra_name]}.xml") }
end

execute "install_solr_log_libraries" do
  cwd    "#{node['fedora-commons'][:installDir]}"
  user   'root'
  command "cp -pr solr-#{node[:solr][:version]}/example/lib/ext/* /usr/share/tomcat7/lib"

  not_if { ::File.exists?("/usr/share/tomcat7/lib/slf4j-log4j12-1.6.6.jar") }
end

template "/usr/share/tomcat7/lib/log4j.properties" do
  source "log4j.properties.erb"
  owner  'root'
end

#
# Restart Tomcat
#

execute "restart_tomcat" do
  user    'root'
  command "service tomcat7 restart"
end


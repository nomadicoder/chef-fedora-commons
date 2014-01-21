#
# Cookbook Name:: curate
# Recipe:: default
#
# Copyright 2014, Steven K. Ng
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

#
# Clone the git repo & install gems
#

git "/opt/#{node[:solr][:hydra_name]}"  do
  repository node[:curate][:git_repo]
  reference node[:curate][:git_branch]
  action :sync
  user 'root'
end

execute "change_hydra_owner" do
  user 'root'
  command "chown -R #{node['fedora-commons'][:tomcat_user]}:#{node['fedora-commons'][:tomcat_user]} /opt/#{node[:solr][:hydra_name]}"
end

execute "install_bundler" do
  user   'root'
  command "gem install bundler --no-rdoc --no-ri"
end

execute "install_ruby_gems" do
  cwd     "/opt/#{node[:solr][:hydra_name]}"
  user   'root'
  command "bundle install"
end

#
# Install and Configure Nginx
#

package "nginx"

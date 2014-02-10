#
# Cookbook Name:: curate_app
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

package "clamav"

#
# Install FFmpeg
#

package "autoconf"
package "automake"

directory "#{node['ffmpeg'][:source_dir]}" do
  action :create
end

script "install Yasm" do
  interpreter "bash"
  cwd "#{node['ffmpeg'][:source_dir]}"
  user "root"
  code <<-EOH
wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
tar xzvf yasm-1.2.0.tar.gz
cd yasm-1.2.0
./configure --prefix="#{node['ffmpeg'][:source_dir]}" --bindir="#{node['ffmpeg'][:bin_dir]}"
make
make install
make distclean
  EOH
end

script "install x264" do
  interpreter "bash"
  cwd "#{node['ffmpeg'][:source_dir]}"
  user "root"
  code <<-EOH
git clone --depth 1 git://git.videolan.org/x264.git
cd x264
./configure --prefix="#{node['ffmpeg'][:source_dir]}" --bindir="#{node['ffmpeg'][:bin_dir]}" --enable-static
make
make install
make distclean
  EOH
end

script "install fdk-aac" do
  interpreter "bash"
  cwd "#{node['ffmpeg'][:source_dir]}"
  user "root"
  code <<-EOH
git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="#{node['ffmpeg'][:source_dir]}" --disable-shared
make
make install
make distclean
  EOH
end

package "libmp3lame"

script "install libvpx" do
  interpreter "bash"
  cwd "#{node['ffmpeg'][:source_dir]}"
  user "root"
  code <<-EOH
git clone --depth 1 http://git.chromium.org/webm/libvpx.git
cd libvpx
./configure --prefix="#{node['ffmpeg'][:source_dir]}" --disable-examples
make
make install
make clean
  EOH
end

package "libtheora-dev"
package "libvorbis-dev"

apt_repository "multiverse" do
  uri "http://archive.ubuntu.com/ubuntu"
  distribution "natty"
  components ["main" "restricted" "universe" "multiverse"]
  action :add
  notifies :run, "execute[apt-get update]", :immediately
end

package "libfaac-dev"

#
# Clone the git 
#

#git "#{node['ffmpeg'][:source_dir]}/ffmpeg_build"  do
#  repository 'git://source.ffmpeg.org/ffmpeg'
#  action :sync
#  user 'root'
#end

#
# Install FITS
# 

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

#
# Install Redis
# 

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
  repository node[:curate_app][:git_repo]
  reference node[:curate_app][:git_branch]
  action :sync
  user 'root'
end

execute "change_hydra_owner" do
  user 'root'
  command "chown -R #{node[:curate_app][:user]}:#{node[:curate_app][:user]} /opt/#{node[:solr][:hydra_name]}"
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

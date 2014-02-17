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
package "build-essential"
package "libass-dev"
package "libgpac-dev"
package "libsdl1.2-dev"
package "libtheora-dev"
package "libtool"
package "libva-dev"
package "libvdpau-dev"
package "libvorbis-dev"
package "libx11-dev"
package "libxext-dev"
package "libxfixes-dev"
package "pkg-config"
package "texi2html"
package "zlib1g-dev"

directory "#{node[:ffmpeg][:source_dir]}" do
  action :create
end

script "download Yasm" do
  interpreter "bash"
  cwd "#{node[:ffmpeg][:source_dir]}"
  user "root"
  code <<-EOH
    wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
    tar xzvf yasm-1.2.0.tar.gz
  EOH
  not_if { ::File.exists?("#{node[:ffmpeg][:source_dir]}/yasm-1.2.0") }
end

script "install Yasm" do
  interpreter "bash"
  cwd "#{node[:ffmpeg][:source_dir]}/yasm-1.2.0"
  user "root"
  code <<-EOH
    ./configure --prefix="#{node[:ffmpeg][:build_dir]}" --bindir="#{node[:ffmpeg][:bin_dir]}"
    make
    make install
    make distclean
  EOH
  not_if { ::File.exists?("#{node[:ffmpeg][:bin_dir]}/yasm") }
end

#execute "download_x264" do
#  cwd "#{node[:ffmpeg][:source_dir]}"
#  user "root"
#  command "wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2"
#
#  not_if { ::File.exists?("#{node[:ffmpeg][:source_dir]}/last_x264.tar.bz2") }
#end

#execute "uncompress_x264" do
#  cwd "#{node[:ffmpeg][:source_dir]}"
#  user "root"
#  command "tar xjvf last_x264.tar.bz2"
#
#  not_if { ::File.exists?("#{node[:ffmpeg][:source_dir]}/x264-snapshot*") }
#end

#script "install x264" do
#  interpreter "bash"
#  cwd "#{node[:ffmpeg][:source_dir]}/x264-snapshot*"
#  user "root"
#  code <<-EOH
#    export PATH=#{node[:ffmpeg][:bin_dir]}:$PATH
#    ./configure --prefix="#{node[:ffmpeg][:build_dir]}" --bindir="#{node[:ffmpeg][:bin_dir]}" --enable-static
#    make
#    make install
#    make distclean
#  EOH
#  not_if { ::File.exists?("#{node[:ffmpeg][:bin_dir]}/x264") }
#end

package "x264"
package "libx264-dev"

git "#{node[:ffmpeg][:source_dir]}/fdk-aac"  do
  repository 'git://git.code.sf.net/p/opencore-amr/fdk-aac'
  action :sync
  user 'root'
end

script "install fdk-aac" do
  interpreter "bash"
  cwd "#{node[:ffmpeg][:source_dir]}/fdk-aac"
  user "root"
  code <<-EOH
    autoreconf -fiv
    ./configure --prefix="#{node[:ffmpeg][:build_dir]}" --disable-shared
    make
    make install
    make distclean
  EOH
  not_if { ::File.exists?("#{node[:ffmpeg][:lib_dir]}/libfdk-aac.a") }
end

package "libmp3lame-dev"

git "#{node[:ffmpeg][:source_dir]}/libvpx"  do
  repository 'http://git.chromium.org/webm/libvpx.git'
  action :sync
  user 'root'
end

script "install libvpx" do
  interpreter "bash"
  cwd "#{node[:ffmpeg][:source_dir]}/libvpx"
  user "root"
  code <<-EOH
    export PATH=#{node[:ffmpeg][:bin_dir]}:$PATH
    ./configure --prefix="#{node[:ffmpeg][:build_dir]}" --disable-examples
    make
    make install
    make clean
  EOH
  not_if { ::File.exists?("#{node[:ffmpeg][:lib_dir]}/libvpx.a") }
end

package "libtheora-dev"
package "libvorbis-dev"

#git "#{node[:ffmpeg][:source_dir]}/ffmpeg"  do
#  repository 'git://source.ffmpeg.org/ffmpeg'
#  action :sync
#  user 'root'
#end

script "download ffmpeg" do
  interpreter "bash"
  cwd "#{node[:ffmpeg][:source_dir]}"
  user "root"
  code <<-EOH
    wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
    tar xjvf ffmpeg-snapshot.tar.bz2
  EOH
  not_if { ::File.exists?("#{node[:ffmpeg][:source_dir]}/ffmpeg") }
end

script "build ffmpeg" do
  interpreter "bash"
  cwd "#{node[:ffmpeg][:source_dir]}/ffmpeg"
  user "root"
  code <<-EOH
    export PATH=#{node[:ffmpeg][:bin_dir]}:$PATH
    PKG_CONFIG_PATH="#{node[:ffmpeg][:build_dir]}/lib/pkgconfig"
    export PKG_CONFIG_PATH
    ./configure --prefix="#{node[:ffmpeg][:build_dir]}" \
      --extra-cflags="-I#{node[:ffmpeg][:include_dir]}" --extra-ldflags="-L#{node[:ffmpeg][:lib_dir]}" \
      --bindir="#{node[:ffmpeg][:bin_dir]}" --extra-libs="-ldl" --enable-gpl --enable-libass --enable-libfdk-aac \
      --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libvpx \
      --enable-libx264 --enable-nonfree --enable-x11grab
    make
    make install
    make distclean
    hash -r
  EOH
  not_if { ::File.exists?("#{node[:ffmpeg][:bin_dir]}/ffmpeg") }
end

#
# Install FITS
# 

script "download fits" do
  interpreter "bash"
  cwd "/opt"
  user "root"
  code <<-EOH
    wget https://fits.googlecode.com/files/fits-0.6.2.zip
  EOH
  not_if { ::File.exists?("/opt/fits-0.6.2.zip") }
end

script "install_fits" do
  interpreter "bash"
  cwd "/opt"
  user "root"
  code <<-EOH
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

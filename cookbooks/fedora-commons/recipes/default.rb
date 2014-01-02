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
  "wget http://downloads.sourceforge.net/fedora-commons/fcrepo-installer-3.7.0.jar"
  EOH

  not_if { ::File.exists?("/home/#{node[:user][:name]}/fcrepo-installer-3.7.0.jar") }
end

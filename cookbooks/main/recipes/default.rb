package "openssl"
package "build-essential"
package "git-core"
package "sqlite3"
package "zlib1g-dev"
package "libtool"
package "libyaml-dev"
package "libxslt-dev"
package "libxml2-dev"
package "libsqlite3-dev"
package "python-software-properties"
package "openjdk-7-jre"
package "nodejs"
package "imagemagick"
package "graphicsmagick-libmagick-dev-compat"
package "tomcat7"

user node[:user][:name] do
  password node[:user][:password]
  home "/home/#{node[:user][:name]}"
  supports manage_home: true
  shell "/bin/bash"
end

group "sudo" do
  action :modify
  members node[:user][:name]
  append true
end

group "tomcat7" do
  action :modify
  members node[:user][:name]
  append true
end

template "/home/#{node[:user][:name]}/.bashrc" do
  source "bashrc.erb"
  owner node[:user][:name]
end

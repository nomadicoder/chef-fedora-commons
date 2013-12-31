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

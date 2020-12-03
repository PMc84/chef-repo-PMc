#
# Cookbook:: lamp_stack
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

execute "update-upgrade" do
  command "sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"
  action :run
end

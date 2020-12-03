# install & enable apache

# install the package with the name Apache2
package "apache2" do
  action :install
end

# ensure that the service apache2 is enabled and started - if not do this
service "apache2" do
  action [:enable, :start]
end

# Virtual Host Files

# We are pulling attributes from ~/chef-repo/cookbooks/lamp_stack/attributes/default.rb

node["lamp_stack"]["sites"].each do |sitename, data|

# here we create the root directory for each of the sites defined in the attributes file
  document_root = "/var/www/html/#{sitename}"

  directory document_root do
# set permission on the directory
    mode "0755"
# recursive creates all directories upto the directory specified 
    recursive true
  end

# we run the command a2ensite to enable the specific site - action :nothing means no action is taken until we excute this  
  execute "enable-sites" do
    command "a2ensite #{sitename}"
    action :nothing
  end

# we use the template command to create a file based on the content of ~/chef-repo/cookbooks/lamp_stack/templates/virtualhosts.erb as referenced in the source field - we then set the permissions as 0644 and specify symbols to complete the template
  template "/etc/apache2/sites-available/#{sitename}.conf" do
    source "virtualhosts.erb"
    mode "0644"
    variables(
      :document_root => document_root,
      :port => data["port"],
      :serveradmin => data["serveradmin"],
      :servername => data["servername"]
    )
# we now execute the previously defined enable_sites
    notifies :run, "execute[enable-sites]"
# and restart the apache2 service
    notifies :restart, "service[apache2]"
  end

# as part of the template file above, we specified specific folders, we are creating those here  
  directory "/var/www/html/#{sitename}/public_html" do
    action :create
  end
  directory "/var/www/html/#{sitename}/logs" do
    action :create
  end
  
  # Here we are changing a specific part of the apache2.conf file - using sed to replace keepalive on with keepalive off
  execute "keepalive" do
    command "sed -i 's/KeepAlive On/KeepAlive Off/g' /etc/apache2/apache2.conf"
    action :run
  end

# Running the command a2endmod mpm-prefork, as before, action :nothing so this will do nothing till called
  execute "enable-prefork" do
    command "a2dismod mpm_event || a2enmod mpm_prefork"
    action :nothing
  end

# cookbook_file adds a static file - this does not have any variables and is static - it is being sourced from ~/chef-repo/cookbooks/lamp_stack/files/default/mpm_prefork.conf, once laid down, we are calling the  the enable-prefork section
  cookbook_file "/etc/apache2/mods-available/mpm_prefork.conf" do
    source "mpm_prefork.conf"
    mode "0644"
    notifies :run, "execute[enable-prefork]"
  end
end

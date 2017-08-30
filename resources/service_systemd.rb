provides :nexus3_service_systemd

provides :nexus3_service, os: 'linux' do |_node|
  ::Chef::Platform::ServiceHelpers.service_resource_providers.include?(:systemd)
end

property :instance_name, String, name_property: true
property :install_dir, String
property :nexus3_user, String
property :nexus3_group, String

action :start do
  create_init

  service "nexus3_#{new_resource.instance_name}" do
    supports restart: true, status: true
    action :start
    only_if 'command -v java >/dev/null 2>&1 || exit 1'
  end
end

action :stop do
  service "nexus3_#{new_resource.instance_name}" do
    supports status: true
    action :stop
  end
end

action :restart do
  service "nexus3_#{new_resource.instance_name}" do
    supports status: true
    action :restart
  end
end

action :disable do
  service "nexus3_#{new_resource.instance_name}" do
    supports status: true
    action :disable
  end
end

action :enable do
  create_init

  service "nexus3_#{new_resource.instance_name}" do
    supports status: true
    action :enable
  end
end

action_class do
  def create_init
    systemd_service "nexus3_#{new_resource.instance_name}" do
      triggers_reload true

      unit do
        description "nexus service (#{new_resource.instance_name})"
        after 'network.target'
      end

      service do
        type 'forking'
        exec_start "#{new_resource.install_dir}/bin/nexus start"
        exec_stop "#{new_resource.install_dir}/bin/nexus stop"
        user new_resource.nexus3_user
        restart 'on-abort'
      end

      install do
        wanted_by 'multi-user.target'
      end
    end
  end
end

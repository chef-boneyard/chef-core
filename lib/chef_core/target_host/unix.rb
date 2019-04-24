

module ChefCore
  class TargetHost
    module Unix
      require "chef_core/target_host/linux"
      # Most of our supported behaviors are the same on linux
      include ChefCore::TargetHost::Linux

      # This one is not, and is not supported yet.
      def install_package(target_package_path)
        raise NotImplementedError
      end
    end
  end
end

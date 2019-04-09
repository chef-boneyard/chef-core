module ChefCore
  module Errors
    # Provides mappings of common errors that we don't explicitly
    # handle, but can offer expanded help text around.
    class StandardErrorResolver
      def self.resolve_exception(exception)
        deps
        case exception
        when OpenSSL::SSL::SSLError
          if exception.message =~ /SSL.*verify failed.*/
            id = "CHEFNET002"
          end
        when SocketError then id = "CHEFNET001"
        end
        if id.nil?
          exception
        else
          ChefCore::Error.new(id, exception.message)
        end
      end

      def self.wrap_exception(original, target_host = nil)
        resolved_exception = resolve_exception(original)
        WrappedError.new(resolved_exception, target_host)
      end

      def self.unwrap_exception(wrapper)
        resolve_exception(wrapper.contained_exception)
      end

      def self.deps
        # Avoid loading additional includes until they're needed
        require "socket"
        require "openssl"
      end
    end
  end
end

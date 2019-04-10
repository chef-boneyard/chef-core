#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
# License:: Apache License, Version 2.0
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
#

require "chef_core/error"
# TODO - this is a workaround that goes with having to specify inheritence in the module declaration
#        should not be needed, and we need to track down why (here and in action classes)
require "chef_core/actions/base"

module ChefCore
  module Actions
    class ConvergeTarget < Base
      # This converts chef client run failures
      # to human-friendly exceptions with detail
      # and remediation steps based on the failure type.
      class CCRFailureMapper
        attr_reader :params

        def initialize(exception, params)
          @params = params
          @cause_line = exception
        end

        def raise_mapped_exception!
          if @cause_line.nil?
            raise RemoteChefRunFailedToResolveError.new(params[:failed_report_path])
          else
            errid, *args = exception_args_from_cause()
            if errid.nil?
              raise RemoteChefClientRunFailedUnknownReason.new()
            else
              raise RemoteChefClientRunFailed.new(errid, *args)
            end

          end
        end

        # Ideally we will write a custom handler to package up data we care
        # about and present it more directly  https://docs.chef.io/handlers.html
        # For now, we'll just match the most common failures based on their
        # messages.
        def exception_args_from_cause
          # Ordering is important below.  Some earlier tests are more detailed
          # cases of things that will match more general tests further down.
          case @cause_line
          when /.*had an error:(.*:)\s+(.*$)/
            # Some invalid property value cases, among others.
            ["CHEFCCR002", $2]
          when /.*Chef::Exceptions::ValidationFailed:\s+Option action must be equal to one of:\s+(.*)!\s+You passed :(.*)\./
            # Invalid action - specialization of invalid property value, below
            ["CHEFCCR003", $2, $1]
          when /.*Chef::Exceptions::ValidationFailed:\s+(.*)/
            # Invalid resource property value
            ["CHEFCCR004", $1]
          when /.*NameError: undefined local variable or method `(.+)' for cookbook.+/
            # Invalid resource type in most cases
            ["CHEFCCR005", $1]
          when /.*NoMethodError: undefined method `(.+)' for cookbook.+/
            # Invalid resource type in most cases
            ["CHEFCCR005", $1]
          when /.*undefined method `(.*)' for Chef::Resource::(.+)::/
            # If we can get a resource name show that instead of the class name
            # TODO - for the best experience, we could instantiate the resource in invoke resource.name
            ["CHEFCCR006", $1, $2]
          when /.*undefined method `(.*)' for (.+)/
            # TODO - we started showing the class name instead of hte resource name.
            # name, which is confusing -
            # 'blah' is not a property of 'Chef::Resource::User::LinuxUser'.
            #

            ["CHEFCCR006", $1, $2]

            # Below would catch the general form of most errors, but the
            # message itself in those lines is not generally aligned
            # with the UX we want to provide.
            # when /.*Exception|Error.*:\s+(.*)/
          else
            nil
          end
        end

        class RemoteChefClientRunFailed < ChefCore::Error
          def initialize(id, *args); super(id, *args); end
        end

        class RemoteChefClientRunFailedUnknownReason < ChefCore::Error
          def initialize(); super("CHEFCCR099"); end
        end

        class RemoteChefRunFailedToResolveError < ChefCore::Error
          def initialize(path); super("CHEFCCR001", path); end
        end

      end

    end
  end
end

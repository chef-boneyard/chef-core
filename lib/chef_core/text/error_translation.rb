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

module ChefCore
  module Text
    # Represents an error loaded from translation, with
    # display attributes set.
    class ErrorTranslation
      ATTRIBUTES = %i{decorations header footer stack log}.freeze
      attr_reader :message, *ATTRIBUTES

      def initialize(id, params: [])
        error_translation = error_translation_for_id(id)

        options = _sym(YAML.load(Text.errors.display_defaults, "display_defaults"))

        # Display metadata is a string containing a YAML hash that is optionally under
        # the error's 'options' attribute
        # Note that we couldn't use :display, as that conflicts with a method on Object.
        display_opts = if error_translation.methods.include?(:options)
                         _sym(YAML.load(error_translation.options, @id))
                       else
                         {}
                       end

        options = options.merge(display_opts) unless display_opts.nil?

        @message = error_translation.text(*params)

        ATTRIBUTES.each do |attribute|
          instance_variable_set("@#{attribute}", options.delete(attribute))
        end

        if options.length > 0
          # Anything not in ATTRIBUTES is not supported. This will also catch
          # typos in attr names
          raise InvalidDisplayAttributes.new(id, options)
        end
      end

      def _sym(hash)
        hash.map { |k, v| [k.to_sym, v] }.to_h
      end

      def inspect
        inspection = "#{self}: "
        ATTRIBUTES.each do |attribute|
          inspection << "#{attribute}: #{send(attribute.to_s)}; "
        end
        inspection << "message: #{message.gsub("\n", "\\n")}"
        inspection
      end

      private

      # This is split out for simplified unit testing of error formatting.
      def error_translation_for_id(id)
        Text.errors.send(id)
      end

      class InvalidDisplayAttributes < RuntimeError
        attr_reader :invalid_attrs
        def initialize(id, attrs)
          @invalid_attrs = attrs
          super("Invalid display attributes found for #{id}: #{attrs}")
        end
      end

    end
  end
end

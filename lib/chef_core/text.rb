#
# Copyright:: Copyright (c) 2018-2019 Chef Software Inc.
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

require "r18n-desktop"
require "chef_core/text/text_wrapper"
require "chef_core/text/error_translation"

# A very thin wrapper around R18n, the idea being that we're likely to replace r18n
# down the road and don't want to have to change all of our commands.
module ChefCore
  module Text

    DEFAULT_LOCALIZATION_PATH = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "i18n"))

    # Set up this gem's localization as the only one present
    def self.reset!
      @localization_paths = []
      @raw_localization_paths = []
      add_localization(DEFAULT_LOCALIZATION_PATH)
    end

    def self.add_localization(base_path)
      return if @raw_localization_paths.include? base_path

      # @localization_paths will get modified by R18n, so we'll
      # keep them as strings as well, to ensure we can avoid duplicate loading.
      errors_path = File.join(base_path, "errors")
      @localization_paths << base_path
      @localization_paths << errors_path
      @raw_localization_paths << base_path
      @raw_localization_paths << errors_path
      reload!
    end

    def self.add_gem_localization(gem_name)
      spec = Gem::Specification.find_by_name(gem_name)
      path = File.join(spec.gem_dir, "i18n")
      if File.directory? path
        add_localization(path)
      end
    end

    def self.reload!
      R18n.reset!
      R18n.from_env(@localization_paths)
      t = R18n.get.t
      t.translation_keys.each do |k|
        k = k.to_sym
        define_singleton_method k do |*args|
          # If this is a top-level entry without children
          # (such as 'cancel') it will have no translation
          # keys and doees not need a wrapper
          tree = t.send(k, *args)
          if tree.methods.include?(:translation_keys)
            TextWrapper.new(tree)
          else
            tree.to_s
          end
        end
      end
    end
    # Load this gem's built-in errors during class load to ensure that
    # error display info will be available.
    reset!
  end
end

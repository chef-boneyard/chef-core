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

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef_core/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-core-actions"
  spec.version       = ChefCore::VERSION
  spec.authors       = ["Chef Software, Inc"]
  spec.email         = ["workstation@chef.io"]

  spec.summary     = "Common functionality for Chef ruby components"
  spec.description = "Common functionality for Chef ruby components"
  spec.homepage    = "https://github.com/chef/chef_core"
  spec.license     = "Apache-2.0"
  spec.required_ruby_version = ">= 2.4.0"

  spec.files = %w{ LICENSE lib/chef_core/actions.rb } +
    Dir.glob("{i18n,lib/chef_core/actions}/**/*", File::FNM_DOTMATCH)
  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-log" # Basis for our traditional logger
  spec.add_dependency "chef-core"
  spec.add_dependency "chef-config" # Provides the PathHelper utility

end

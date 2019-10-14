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
  spec.name          = "chef-core"
  spec.version       = ChefCore::VERSION
  spec.authors       = ["Chef Software, Inc"]
  spec.email         = ["workstation@chef.io"]

  spec.summary     = "Composable common actions for assembling Chef workflows"
  spec.description = "Composable common actions for assembling Chef workflows"
  spec.homepage    = "https://github.com/chef/chef_core"
  spec.license     = "Apache-2.0"
  spec.required_ruby_version = ">= 2.4.0"

  spec.files = %w{ LICENSE } +
    Dir.glob("{i18n,lib,resources}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) || f =~ %r{chef_core/actions.*$} }
  spec.require_paths = ["lib"]

  spec.add_dependency "pastel" # A color library
  spec.add_dependency "tty-spinner" # The tty-* libraries are a nice set of terminal output gems
  spec.add_dependency "tty-color"
  spec.add_dependency "tty-cursor"

  spec.add_dependency "mixlib-log" # Basis for our traditional logger
  spec.add_dependency "train-core", ">= 2.0.12", "< 4" # we need 2.0.12+ to get winrm and ssh support
  spec.add_dependency "chef-telemetry", "~> 1.0"
  spec.add_dependency "r18n-desktop" # easy path to message text management via localization gem...
end

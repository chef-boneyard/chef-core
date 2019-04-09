#
# Copyright:: Copyright (c) 2019 Chef Software Inc.
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

require "chef_core/text"

RSpec.describe ChefCore::Text do
  subject { ChefCore::Text }
  after do
    subject.reset!
  end

  context "default" do
    it "it loads default i18n tables and resolves a nested key correctly" do
      # We reference a known key that we ship in this gem's default localization
      expect(ChefCore::Text.errors.footer.neither).to match(/resolve/)
    end

    it "resolves a top-level key correctly to its text" do
      # "cancel" is provided by R18n.  Top-level keys
      # need to be tested separately because they have no need of
      # the TextWrapper behaviors and will directly return a string
      expect(ChefCore::Text.cancel).to eq "Cancel"
    end

    context "nested keys resolve correctly to text" do
    end
  end

  context "::add_localization" do
    context "when a secondary localization is added" do
      before do
        subject.add_localization("spec/unit/fixtures/i18n")
      end

      it "retains the original translations" do
        expect(ChefCore::Text.cancel).to eq "Cancel"
      end

      it "merges the translations into the existing ones" do
        t = ChefCore::Text.testing.hello_world
        expect(t).to eq "Hello world!"
      end
      it "merge includes contents of errors/en.yml" do
        t = ChefCore::Text.errors.TEST001.text
        expect(t).to eq "Hey."
      end

    end
  end
end

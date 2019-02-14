
require "chef_core/text"

module ChefCore
  module CLIUX
    GEM_LOCALIZATION_PATH = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "i18n"))
    # Initialize our own translations on load
    ChefCore::Text.add_localization(GEM_LOCALIZATION_PATH)
  end
end


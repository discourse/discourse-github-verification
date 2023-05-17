# frozen_string_literal: true

module ::GithubVerification
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace GithubVerification
    config.autoload_paths << File.join(config.root, "lib")
  end
end

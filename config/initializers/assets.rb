require 'sassc-rails'
# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

Rails.application.config.assets.configure do |env|
  logger = Logger.new("log/assets.log")
  logger.level = Logger::DEBUG
  env.logger = logger
end

# config/initializers/sassc_rails.rb

require "sprockets/engines"

module Extensions
  module Sprockets
    module Engines
      def register_engine(ext, klass)
        return if [
          Sass::Rails::SassTemplate,
          Sass::Rails::ScssTemplate
        ].include?(klass)

        super
      end
    end
  end
end

Sprockets::Base.send(:prepend, Extensions::Sprockets::Engines)

# Rails.application.assets.register_engine '.sass', SassC::Rails::SassTemplate
# Rails.application.assets.register_engine '.scss', SassC::Rails::ScssTemplate

Rails.application.config.assets.configure do |env|
  env.register_engine '.sass', SassC::Rails::SassTemplate
  env.register_engine '.scss', SassC::Rails::ScssTemplate
end

require 'pry'
require 'rspec'
require 'open3'
require 'io/console'
require 'rspec/expectations'

require 'selenium-webdriver'
require 'capybara/rspec'
require 'capybara/dsl'

require 'yaml'
SpecConfig = YAML.load_file('./config/app.yml')

RSpec.configure do |config|
  config.include Capybara::DSL
end

# Capybara.register_driver :selenium_firefox do |app|
#   profile = Selenium::WebDriver::Firefox::Profile.new
#   profile['media.navigator.permission.disabled'] = true
#   profile.assume_untrusted_certificate_issuer = false
#   profile.secure_ssl = false
#
#   Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
# end

Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(app, {browser: :chrome,
    switches: [
      '--allow-file-access',
      '--disable-translate',
      '--always-authorize-plugins',
      '--ignore-certificate-errors',
      '--disable-user-media-security',
      '--use-fake-device-for-media-stream',
      '--disable-extensions-file-access-check',
      '--disable-improved-download-protection',
      '--load-extension=/opt/voice-specs/lib/ember.js'
    ]
  })
end

Capybara.app_host         = "https://#{SpecConfig['hostname']}"
Capybara.run_server       =  false
Capybara.server_port      =  443
Capybara.default_selector = :css
Capybara.default_driver   = :selenium_chrome # :selenium_firefox

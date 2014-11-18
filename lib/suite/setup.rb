require 'pry'
require 'rspec'
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
    switches: %w[--ignore-certificate-errors --disable-translate --use-fake-device-for-media-stream --disable-user-media-security]
  })
end

Capybara.app_host         = "https://#{SpecConfig['hostname']}"
Capybara.run_server       =  false
Capybara.server_port      =  443
Capybara.default_selector = :css
Capybara.default_driver   = :selenium_chrome # :selenium_firefox

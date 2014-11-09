require 'rspec'
require 'rspec/expectations'

require 'selenium-webdriver'
require 'capybara/rspec'
require 'capybara/dsl'

require 'yaml'
SpecConfig = YAML.load_file('./config/app.yml')

RSpec.configure do |config|
  config.include Capybara::DSL
end

Capybara.app_host    = "https://#{SpecConfig['hostname']}"
Capybara.run_server  =  false
Capybara.server_port =  443

Capybara.register_driver :selenium_firefox_driver do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['media.navigator.permission.disabled'] = true
  profile.secure_ssl = false
  profile.assume_untrusted_certificate_issuer = false
  Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
end

Capybara.default_driver = :selenium_firefox_driver

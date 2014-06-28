require 'bundler'
Bundler.setup

require 'selenium-webdriver'
require 'capybara/rspec'
require 'capybara/dsl'
require 'rspec'

Capybara.app_host    = 'http://33.33.33.100'
Capybara.run_server  =  false
Capybara.server_port =  80

Capybara.register_driver :selenium_firefox_driver do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['media.navigator.permission.disabled'] = true
  Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
end

Capybara.default_driver = :selenium_firefox_driver

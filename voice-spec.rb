#!/usr/bin/env ruby

require 'bundler'
Bundler.setup

require 'selenium-webdriver'
require 'capybara/rspec'
require 'capybara/dsl'
require 'rspec'

Capybara.app_host    = 'http://33.33.33.100'
Capybara.run_server  = false
Capybara.server_port = 80

Capybara.register_driver :selenium_firefox_driver do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['media.navigator.permission.disabled'] = true
  Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
end
Capybara.default_driver = :selenium_firefox_driver

module Session
  extend Capybara::DSL

  def self.start
    visit '/'
    sleep 2
    page.execute_script "lo = {login: '101', password: '0000'}; phone.app.login(lo); phone.app.getAccessToAudio();"
    sleep 2
    page.execute_script "phone.app.call('000');"
    sleep 1
    page.execute_script "cid = phone.app.calls[0].id;"
    sleep 6
    # puts ">>> send DTMF 1"
    page.execute_script "phone.app.sendDTMF(cid, '1');"
    sleep 10
    # puts ">>> send DTMF 2"
    page.execute_script "phone.app.sendDTMF(cid, '2');"
    sleep 5
  end
end

threads = []
count   = 1

(1..count).each do |n|
  threads << Thread.new {
    Capybara.session_name = "session_#{n}"
    Session.start
  }
end

threads.map { |t| t.join }

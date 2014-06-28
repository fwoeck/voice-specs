#!/usr/bin/env ruby

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

require './lib/voice_helper'

module Session
  extend Capybara::DSL

  def self.start
    visit '/'
    sleep 2
    get_audio_access
    register_as(101)
    sleep 2
    call('000')
    sleep 1
    get_callid
    sleep 6
    send_dtmf(1)
    sleep 10
    send_dtmf(2)
    sleep 5
  end
end

# count > 1 causes havoc with the FF audio device:
threads = []
count   = 1

(1..count).each do |n|
  threads << Thread.new {
    Capybara.session_name = "client_#{n}"
    Session.start
  }
end

threads.map { |t| t.join }

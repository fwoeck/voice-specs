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
    Capybara.session_name = :client_1
    visit '/'
    sleep 2
    get_audio_access
    register_as(101)
    sleep 2

    Capybara.session_name = :client_2
    visit '/'
    sleep 2
    get_audio_access
    register_as(102)
    sleep 2
    call('101')

    Capybara.session_name = :client_1
    sleep 3
    get_callid
    answer_call
    sleep 3
    send_dtmf(1)
    sleep 1
    send_dtmf(2)
    sleep 1
    hangup_call
  end
end

Session.start

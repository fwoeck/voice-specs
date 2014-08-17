#!/usr/bin/env ruby

require './lib/setup'
require './lib/helpers'

NUM = ARGV[0] || 1

module Session
  extend Capybara::DSL
  extend RSpec::Matchers


  def self.start
    use_client(NUM)
    visit_home_url
    login_as('100@mail.com')
  rescue => e
    puts e.message
  end


  def self.stop
    Capybara.reset_sessions!
  end
end

Session.start
Session.stop

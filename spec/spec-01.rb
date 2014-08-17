#!/usr/bin/env ruby

require './lib/setup'
require './lib/helpers'

module Session
  extend Capybara::DSL
  extend RSpec::Matchers


  def self.start
    use_client(100)
    visit_home_url
    login_as('100@mail.com')

    use_client(101)
    visit_home_url
    login_as('101@mail.com')

    use_client(103)
    visit_home_url
    login_as('103@mail.com')
  rescue => e
    puts e.message
  ensure
    Capybara.reset_sessions!
  end
end

Session.start

#!/usr/bin/env ruby

require './lib/setup'
require './lib/helpers'

NUM = ARGV[0] || 1

module Session
  extend Capybara::DSL

  def self.start
    use_client(NUM)
    visit_home_url
    sleep 2
    get_audio_access
    register_as(101)
    sleep 2
    call('000')
    sleep 2
    get_callid
    sleep 6
    send_dtmf(1)
    sleep 10
    send_dtmf(2)
    sleep 10
    hangup_call
  end
end

Session.start

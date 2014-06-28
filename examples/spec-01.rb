#!/usr/bin/env ruby
require './lib/setup'
require './lib/helpers'

module Session
  extend Capybara::DSL

  def self.start(n)
    use_client(n)
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
    sleep 5
  end
end

# count > 1 causes havoc with the FF audio device:
threads = []
count   = 1

(1..count).each do |n|
  threads << Thread.new {
    Session.start(n)
  }
end

threads.map { |t| t.join }

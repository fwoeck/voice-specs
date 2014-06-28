#!/usr/bin/env ruby

# Launch this from your physical host (audio device & firefox needed):
# > examples/spec-01.rb
#
# You can spawn multiple browsers at once:
# > examples/spec-01.rb 1 & examples/spec-01.rb 2 & examples/spec-01.rb 3 &
#
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
    sleep 5
  end
end

Session.start

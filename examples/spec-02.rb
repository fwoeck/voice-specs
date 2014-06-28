#!/usr/bin/env ruby
require './lib/setup'
require './lib/helpers'

module Session
  extend Capybara::DSL

  def self.start
    use_client(1)
    visit '/'
    sleep 2
    get_audio_access
    register_as(101)
    sleep 2

    use_client(2)
    visit '/'
    sleep 2
    get_audio_access
    register_as(102)
    sleep 2
    call('101')

    use_client(1)
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

#!/usr/bin/env ruby
require 'bundler'
Bundler.setup

require 'sippy_cup'
require 'yaml'

conf      = YAML.load_file('./config/app.yml')
index     = 0
numbers   = ['1', '2', '3', '4', '2'].cycle
scenarios = []

5.times do
  index += 1
  conf[:source_port] = 8836 + index

  scenarios << SippyCup::Scenario.new(conf[:name], conf) do |s|
    s.invite
    s.invite conf[:from_user], conf[:password]
    s.receive_trying
    s.receive_ringing
    s.receive_answer
    s.ack_answer

    s.sleep 10
    s.send_digits numbers.next
    s.sleep 10
    s.send_digits numbers.next
    s.sleep 25

    s.send_bye
    s.receive_answer
  end
end

scenarios.map { |s|
  sleep 10
  Thread.new {
    SippyCup::Runner.new(s, full_sipp_output: false).run
  }
}.map(&:join)

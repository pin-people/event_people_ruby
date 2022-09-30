#!/usr/bin/env ruby

ENV['RABBIT_URL'] = 'amqp://guest:guest@localhost:5672'
ENV['RABBIT_EVENT_PEOPLE_APP_NAME'] = 'EventPeopleExampleApp'
ENV['RABBIT_EVENT_PEOPLE_VHOST'] = 'event_people'
ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME'] = 'event_people'

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'rubygems'
require 'bundler'
Bundler.require(:default, 'development')

require_relative '../lib/event_people'

event_name = 'resource.origin.action'

puts 'Start receiving messages'

EventPeople::Listener.on(event_name) do |event, context|
  puts ''
  puts "  - Received a message from #{event.name}:"
  puts "     Message: #{event.body}"
  puts ''

  context.success!
end

# Wait for job to finish!
sleep(0.5)

puts 'Stop receiving messages'

EventPeople::Config.broker.close_connection

#!/usr/bin/env ruby

ENV['RABBIT_URL'] = 'amqp://guest:guest@localhost:5672'
ENV['RABBIT_EVENT_PEOPLE_APP_NAME'] = 'EventPeopleExampleApp'
ENV['RABBIT_EVENT_PEOPLE_VHOST'] = 'event_people'
ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME'] = 'event_people'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'
Bundler.require(:default, 'development')

require_relative '../lib/event_people'

class CustomEventListener < EventPeople::Listeners::Base
  bind :pay, 'resource.custom.pay'
  bind :receive, 'resource.custom.receive'
  bind :private_channel, 'resource.custom.private.service'

  def pay(event)
    puts "Paid #{event.body['amount']} for #{event.body['name']} ~> #{event.name}"

    success!
  end

  def receive(event)
    if event.body['amount'] > 500
      puts "Received #{event.body['amount']} from #{event.body['name']} ~> #{event.name}"
    else
      puts '[consumer] Got SKIPPED message'

      return reject!
    end

    success!
  end

  def private_channel(event)
    puts "[consumer] Got a private message: \"#{event.body['message']}\" ~> #{event.name}"

    success!
  end
end

puts '****************** Daemon Ready ******************'

EventPeople::Daemon.start

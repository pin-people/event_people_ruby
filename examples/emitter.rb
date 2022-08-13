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

events = []

event_name = 'resource.custom.pay'
body = { amount: 1500, name: 'John' }

events.push(EventPeople::Event.new(event_name, body))

event_name = 'resource.custom.receive'
body = { amount: 35, name: 'Peter' }

events.push(EventPeople::Event.new(event_name, body))

event_name = 'resource.custom.receive'
body = { amount: 350, name: 'George' }

events.push(EventPeople::Event.new(event_name, body))

event_name = 'resource.custom.receive'
body = { amount: 550, name: 'James' }

events.push(EventPeople::Event.new(event_name, body))

event_name = 'resource.custom.private.service'
body = { message: 'Secret' }

events.push(EventPeople::Event.new(event_name, body))

event_name = 'resource.origin.action'
body = { bo: 'dy' }
schema_version = 4.2

event = EventPeople::Event.new(event_name, body, schema_version)

p 'Sending messsages.'

EventPeople::Emitter.trigger(event)
EventPeople::Emitter.trigger(events)

p 'Mesages sent!'

EventPeople::Config.broker.close_connection
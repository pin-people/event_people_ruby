# Define all environment varibles for specs
ENV['RABBIT_EVENT_PEOPLE_APP_NAME'] = "app_name"
ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME'] = "EVENT_PEOPLE"
ENV['RABBIT_EVENT_PEOPLE_VHOST'] = "EVENT_PEOPLE"
ENV['RABBIT_URL'] = "amqp://guest:guest@localhost:5672"

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

Bundler.require(:default, 'test')

require 'rubygems'
require 'pry'
require_relative '../lib/event_people'

RSpec.configure do |config|
  config.order = :random

  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with(:rspec) do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end
end

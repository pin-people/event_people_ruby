require 'event_people/version'
require 'event_people/daemon'
require 'event_people/event'
require 'event_people/config'
require 'event_people/emitter'
require 'event_people/listener'
require 'event_people/listeners/base'
require 'event_people/listeners/manager'
require 'event_people/broker/base'
require 'event_people/broker/context'
require 'event_people/broker/rabbit'
require 'event_people/broker/rabbit/queue'
require 'event_people/broker/rabbit/rabbit_context'
require 'event_people/broker/rabbit/topic'

module EventPeople
  class MissingAttributeError < StandardError; end
end

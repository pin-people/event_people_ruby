module EventPeople
  class Config
    APP_NAME = ENV['RABBIT_EVENT_PEOPLE_APP_NAME']
    TOPIC    = ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME']
    VHOST    = ENV['RABBIT_EVENT_PEOPLE_VHOST']
    URL      = ENV['RABBIT_URL']
    FULL_URL = "#{ENV['RABBIT_URL']}/#{ENV['RABBIT_EVENT_PEOPLE_VHOST']}"

    def self.broker
      EventPeople::Broker::Rabbit
    end
  end
end

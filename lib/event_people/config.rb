module EventPeople
  class Config
    APP_NAME = ENV['RABBIT_EVENT_PEOPLE_APP_NAME']
    TOPIC    = ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME']
    VHOST    = ENV['RABBIT_EVENT_PEOPLE_VHOST']
    URL      = ENV['RABBIT_URL']
    FULL_URL = "#{ENV['RABBIT_URL']}/#{ENV['RABBIT_EVENT_PEOPLE_VHOST']}"

    MAX_ATTEMPTS   = (ENV['RABBIT_EVENT_PEOPLE_MAX_RETRIES'] || 3).to_i
    DELAY_STRATEGY = 'exponential'
    DLQ_NAME       = "#{ENV['RABBIT_EVENT_PEOPLE_APP_NAME']}_dlq"

    def self.broker
      EventPeople::Broker::Rabbit
    end

    def self.get_retry_config
      {
        max_attempts:   MAX_ATTEMPTS,
        delay_strategy: DELAY_STRATEGY,
        dlq_name:       DLQ_NAME
      }
    end
  end
end

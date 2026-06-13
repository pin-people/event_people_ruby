describe EventPeople::Config do
  # Reset class-level state after each example so tests remain isolated.
  after do
    described_class.configure
  end

  it 'has an app name config' do
    expect(EventPeople::Config::APP_NAME).to eq 'app_name'
  end

  it 'has a topic config' do
    expect(EventPeople::Config::TOPIC).to eq 'EVENT_PEOPLE'
  end

  it 'has a vhost config' do
    expect(EventPeople::Config::VHOST).to eq 'EVENT_PEOPLE'
  end

  it 'has a host config' do
    expect(EventPeople::Config::URL).to eq 'amqp://guest:guest@localhost:5672'
  end

  it 'has a full URL config' do
    expect(EventPeople::Config::FULL_URL).to eq 'amqp://guest:guest@localhost:5672/EVENT_PEOPLE'
  end

  it 'has a broker config' do
    expect(EventPeople::Config.broker).to eq EventPeople::Broker::Rabbit
  end

  describe '.max_attempts' do
    it 'returns the default value when configure has not been called' do
      expect(described_class.max_attempts).to eq EventPeople::Config::DEFAULT_MAX_ATTEMPTS
    end

    it 'returns the configured value when configure has been called' do
      described_class.configure(max_attempts: 7)
      expect(described_class.max_attempts).to eq 7
    end
  end

  describe '.initial_delay' do
    it 'returns the default value when configure has not been called' do
      expect(described_class.initial_delay).to eq EventPeople::Config::DEFAULT_INITIAL_DELAY
    end

    it 'returns the configured value' do
      described_class.configure(initial_delay: 500)
      expect(described_class.initial_delay).to eq 500
    end
  end

  describe '.delay_strategy' do
    it 'returns the default value when configure has not been called' do
      expect(described_class.delay_strategy).to eq EventPeople::Config::DEFAULT_DELAY_STRATEGY
    end

    it 'returns the configured value' do
      described_class.configure(delay_strategy: 'fixed')
      expect(described_class.delay_strategy).to eq 'fixed'
    end
  end

  describe '.dlq_name' do
    it 'defaults to {app_name}_dlq' do
      expect(described_class.dlq_name).to eq "#{EventPeople::Config::APP_NAME}_dlq"
    end

    it 'returns the configured value when set via configure' do
      described_class.configure(dlq_name: 'custom_dlq')
      expect(described_class.dlq_name).to eq 'custom_dlq'
    end
  end

  describe '.configure' do
    it 'sets multiple options at once' do
      described_class.configure(
        max_attempts:   5,
        initial_delay:  2000,
        delay_strategy: 'fixed',
        dlq_name:       'my_dlq'
      )
      expect(described_class.max_attempts).to   eq 5
      expect(described_class.initial_delay).to  eq 2000
      expect(described_class.delay_strategy).to eq 'fixed'
      expect(described_class.dlq_name).to       eq 'my_dlq'
    end

    it 'resets to defaults when called with no arguments' do
      described_class.configure(max_attempts: 10)
      described_class.configure
      expect(described_class.max_attempts).to eq EventPeople::Config::DEFAULT_MAX_ATTEMPTS
    end
  end

  describe '.get_retry_config' do
    it 'returns a hash with max_attempts, initial_delay, delay_strategy, and dlq_name' do
      config = described_class.get_retry_config
      expect(config).to include(
        max_attempts:   EventPeople::Config::DEFAULT_MAX_ATTEMPTS,
        initial_delay:  EventPeople::Config::DEFAULT_INITIAL_DELAY,
        delay_strategy: EventPeople::Config::DEFAULT_DELAY_STRATEGY,
        dlq_name:       "#{EventPeople::Config::APP_NAME}_dlq"
      )
    end

    it 'reflects values set via configure' do
      described_class.configure(max_attempts: 5, initial_delay: 250)
      config = described_class.get_retry_config
      expect(config[:max_attempts]).to  eq 5
      expect(config[:initial_delay]).to eq 250
    end
  end
end

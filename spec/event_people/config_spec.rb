describe EventPeople::Config do
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
end

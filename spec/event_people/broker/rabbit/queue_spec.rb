describe EventPeople::Broker::Rabbit::Queue do
  let(:instance) { described_class.new(connection) }
  let(:connection) { double('conn', queue: bindable, prefetch: 1) }
  let(:bindable) { double('bindable', bind: subscribable) }
  let(:subscribable) { double('subscribable', subscribe: block) }
  let(:topic) { 'topic' }
  let(:event) { 'event' }
  let(:routing_key) { 'Routing_KEY' }
  let(:block) { ->(event, context) { true } }

  describe '.new' do
    let(:connection) { double('conn', queue: bindable) }

    subject { instance }

    it 'set channel prefetch to 1' do
      allow(connection).to receive(:prefetch).with(1)

      subject
    end
  end

  describe '.subscribe' do
    before do
      allow(instance).to receive(:subscribe).with(routing_key)
      allow(described_class).to receive(:new).with(connection).and_return(instance)
    end

    subject { described_class.subscribe(connection, routing_key, &block) }

    it 'creates an instance' do
      expect(described_class).to receive(:new).with(connection)

      subject
    end

    it 'calls subscribe on instance with correct parameters' do
      expect(instance).to receive(:subscribe).with(routing_key)

      subject
    end
  end

  describe '#subscribe' do
    let(:queue_options) { { durable: true } }
    let(:queue_name) { "#{EventPeople::Config::APP_NAME.downcase}-#{routing_key.downcase}.all" }

    before do
      allow(EventPeople::Broker::Rabbit::Topic).to receive(:topic).and_return(topic)
    end

    subject { instance.subscribe(routing_key, &block) }

    it 'instantiates a queue with correct attributes' do
      expect(connection).to receive(:queue).with(queue_name, queue_options)

      subject
    end

    it 'bind queue to topic by routing key' do
      expect(bindable).to receive(:bind).with(topic, routing_key:)

      subject
    end

    it 'subscribes to the queue' do
      expect(subscribable).to receive(:subscribe)

      subject
    end

    context 'when message is received' do
      let(:event_name) { 'event_name' }
      let(:delivery_info) { double('delivery_info', routing_key: event_name) }
      let(:properties) { 'properties' }
      let(:payload) { 'payload' }
      let(:context) { double(EventPeople::Broker::Rabbit::RabbitContext) }
      let(:subscribe_block) do
        ->(delivery_info, properties, payload) do
          instance.send(:callback, delivery_info, properties, payload, &block)
        end
      end

      before do
        allow(EventPeople::Event).to receive(:new).with(event_name, payload).and_return(event)
        allow(EventPeople::Broker::Rabbit::RabbitContext).to receive(:new).with(connection, delivery_info).and_return(context)
      end

      it 'calls block with the received event and context' do
        subject

        expect(block).to receive(:call).with(event, context)

        subscribe_block.call(delivery_info, properties, payload)
      end
    end
  end
end

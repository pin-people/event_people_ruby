describe EventPeople::Broker::Rabbit::Queue do
  let(:app_name) { EventPeople::Config::APP_NAME.downcase }
  let(:dlq_name) { "#{EventPeople::Config::APP_NAME}_dlq" }
  let(:dlq_queue) { double('dlq_queue') }
  let(:retry_queue) { double('retry_queue') }
  let(:instance) { described_class.new(connection) }
  let(:connection) do
    double('conn',
      prefetch: 1,
      queue: bindable
    )
  end
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
      allow(instance).to receive(:subscribe).with(routing_key, retry_config: {})
      allow(described_class).to receive(:new).with(connection).and_return(instance)
    end

    subject { described_class.subscribe(connection, routing_key, &block) }

    it 'creates an instance' do
      expect(described_class).to receive(:new).with(connection)

      subject
    end

    it 'calls subscribe on instance with correct parameters' do
      expect(instance).to receive(:subscribe).with(routing_key, retry_config: {})

      subject
    end
  end

  describe '#subscribe' do
    let(:main_queue_options) do
      { durable: true }
    end
    let(:queue_name) { "#{app_name}-#{routing_key.downcase}.all" }
    let(:retry_queue_name) { "#{queue_name}_retry" }

    before do
      allow(EventPeople::Broker::Rabbit::Topic).to receive(:topic).and_return(topic)
      # App-level DLQ: a plain durable queue, no fanout exchange, no binding.
      allow(connection).to receive(:queue).with(dlq_name, durable: true).and_return(dlq_queue)
      # Retry queue
      allow(connection).to receive(:queue).with(
        retry_queue_name,
        durable: true,
        arguments: {
          'x-dead-letter-exchange'    => '',
          'x-dead-letter-routing-key' => queue_name
        }
      ).and_return(retry_queue)
      # Main queue
      allow(connection).to receive(:queue).with(queue_name, main_queue_options).and_return(bindable)
    end

    subject { instance.subscribe(routing_key, &block) }

    it 'instantiates a queue with correct attributes' do
      expect(connection).to receive(:queue).with(queue_name, main_queue_options).and_return(bindable)

      subject
    end

    it 'declares the main queue WITHOUT any dead-letter argument' do
      expect(connection).to receive(:queue) do |name, opts|
        if name == queue_name
          expect(opts).to eq(durable: true)
          expect(opts).not_to have_key(:arguments)
        end
        bindable
      end.at_least(:once)

      subject
    end

    it 'declares a plain durable DLQ and no fanout DLX exchange or binding' do
      expect(connection).to receive(:queue).with(dlq_name, durable: true).and_return(dlq_queue)
      expect(connection).not_to receive(:fanout)
      expect(dlq_queue).not_to receive(:bind)

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
      let(:delivery_info) { double('delivery_info', routing_key: event_name, delivery_tag: 1) }
      let(:headers_hash) { nil }
      let(:properties) { double('properties', headers: headers_hash) }
      let(:payload) { '{"headers":{},"body":{}}' }
      let(:context) { double(EventPeople::Broker::Rabbit::RabbitContext) }
      let(:subscribe_block) do
        ->(delivery_info, properties, payload) do
          instance.send(:callback, delivery_info, properties, payload, queue_name, {}, &block)
        end
      end

      before do
        allow(EventPeople::Broker::Rabbit::RabbitContext).to receive(:new).and_return(context)
      end

      it 'calls block with the received event and context' do
        subject

        expect(block).to receive(:call).with(instance_of(EventPeople::Event), context)

        subscribe_block.call(delivery_info, properties, payload)
      end
    end
  end
end

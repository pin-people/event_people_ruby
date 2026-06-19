RSpec.describe EventPeople::Broker::Rabbit::RabbitContext do
  let(:channel)          { double('channel', default_exchange: default_exchange) }
  let(:default_exchange) { double('default_exchange', publish: nil) }
  let(:delivery_info)    { double('delivery_info', delivery_tag: 42) }

  def build_context(retry_count:, max_retries:, dlq_name: 'test_dlq')
    described_class.new(
      channel,
      delivery_info,
      retry_count: retry_count,
      max_retries: max_retries,
      delay_strategy: 'fixed',
      dlq_name: dlq_name,
      queue_name: 'test_queue',
      original_payload: '{"x":1}'
    )
  end

  describe '#is_last_retry' do
    it 'returns false when not on last attempt' do
      context = build_context(retry_count: 0, max_retries: 3)
      expect(context.is_last_retry).to be false
    end

    it 'returns true on last attempt (retry_count == max_retries - 1)' do
      context = build_context(retry_count: 2, max_retries: 3)
      expect(context.is_last_retry).to be true
    end
  end

  describe '#fail when retries are exhausted' do
    subject(:context) { build_context(retry_count: 3, max_retries: 3) }

    it 'publishes the message to the application-level DLQ and acks' do
      expect(default_exchange).to receive(:publish).with(
        '{"x":1}',
        routing_key: 'test_dlq',
        persistent: true,
        headers: { 'x-event-people-retries' => 3 }
      )
      expect(channel).to receive(:ack).with(42, false)

      context.fail
    end

    it 'nacks without requeue when the DLQ publish fails' do
      allow(default_exchange).to receive(:publish).and_raise(StandardError)
      expect(channel).to receive(:nack).with(42, false, false)

      context.fail
    end
  end

  describe '#reject' do
    it 'publishes the message to the application-level DLQ and acks' do
      context = build_context(retry_count: 0, max_retries: 3)

      expect(default_exchange).to receive(:publish).with(
        '{"x":1}',
        routing_key: 'test_dlq',
        persistent: true,
        headers: { 'x-event-people-retries' => 0 }
      )
      expect(channel).to receive(:ack).with(42, false)

      context.reject
    end

    it 'nacks without requeue when no DLQ name is configured' do
      context = build_context(retry_count: 0, max_retries: 3, dlq_name: '')

      expect(default_exchange).not_to receive(:publish)
      expect(channel).to receive(:nack).with(42, false, false)

      context.reject
    end

    it 'nacks without requeue when the DLQ publish fails' do
      context = build_context(retry_count: 0, max_retries: 3)
      allow(default_exchange).to receive(:publish).and_raise(StandardError)

      expect(channel).to receive(:nack).with(42, false, false)

      context.reject
    end
  end
end

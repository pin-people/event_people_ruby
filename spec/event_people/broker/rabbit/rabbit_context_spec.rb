RSpec.describe EventPeople::Broker::Rabbit::RabbitContext do
  let(:channel)       { double('channel') }
  let(:delivery_info) { double('delivery_info', delivery_tag: 42) }

  def build_context(retry_count:, max_retries:)
    described_class.new(
      channel,
      delivery_info,
      retry_count:      retry_count,
      max_retries:      max_retries,
      delay_strategy:   'fixed',
      dlq_name:         'test_dlq',
      queue_name:       'test_queue',
      original_payload: '{}'
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
end

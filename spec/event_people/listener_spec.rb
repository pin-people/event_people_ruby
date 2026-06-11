describe EventPeople::Listener do
  let(:event_name) { 'resource.origin.action' }
  let(:consumed_event_name) { 'resource.origin.action.all' }
  let(:block) { ->(event, context) { true } }
  let(:retry_config) do
    {
      max_attempts:   EventPeople::Config::MAX_ATTEMPTS,
      delay_strategy: EventPeople::Config::DELAY_STRATEGY,
      dlq_name:       EventPeople::Config::DLQ_NAME
    }
  end

  describe '.on' do
    before do
      allow(EventPeople::Config.broker).to receive(:consume)
    end

    subject { described_class.on(event_name, &block) }

    context 'when event name is present' do
      it 'consumes the event on the broker' do
        expect(EventPeople::Config.broker).to receive(:consume).with(consumed_event_name, retry_config: retry_config)

        subject
      end

      it 'does not raise an MissingAttributeError' do
        expect { subject }.not_to raise_error
      end

      context 'when name does not includes destination' do
        let(:consumed_event_name) { 'resource.origin.action.all' }

        it 'consumes the event with destination on the broker' do
          expect(EventPeople::Config.broker).to receive(:consume).with(consumed_event_name, retry_config: retry_config)

          subject
        end

        it 'does not raise an MissingAttributeError' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'when event name is not present' do
      let(:event_name) { nil }

      it 'does not produce the event on the broker' do
        expect(EventPeople::Config.broker).not_to receive(:consume)

        subject
      rescue EventPeople::MissingAttributeError
        nil
      end

      it 'raises an MissingAttributeError' do
        expect { subject }.to raise_error(EventPeople::MissingAttributeError)
      end
    end
  end
end

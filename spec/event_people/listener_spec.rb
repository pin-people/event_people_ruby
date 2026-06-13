describe EventPeople::Listener do
  let(:event_name) { 'resource.origin.action' }
  let(:consumed_event_name) { 'resource.origin.action.all' }
  let(:block) { ->(event, context) { true } }
  let(:retry_config) { EventPeople::Config.get_retry_config }

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

      context 'when listener_class has custom retry config' do
        let(:custom_listener) do
          Class.new(EventPeople::Listeners::Base) do
            self.max_attempts   = 5
            self.initial_delay  = 500
            self.delay_strategy = 'fixed'
            self.dlq_name       = 'custom_dlq'
          end
        end

        subject { described_class.on(event_name, listener_class: custom_listener, &block) }

        it 'merges listener class retry config with Config defaults' do
          expected_config = {
            max_attempts:   5,
            initial_delay:  500,
            delay_strategy: 'fixed',
            dlq_name:       'custom_dlq'
          }
          expect(EventPeople::Config.broker).to receive(:consume).with(consumed_event_name, retry_config: expected_config)

          subject
        end
      end

      context 'when listener_class has partial retry config' do
        let(:partial_listener) do
          Class.new(EventPeople::Listeners::Base) do
            self.max_attempts = 7
          end
        end

        subject { described_class.on(event_name, listener_class: partial_listener, &block) }

        it 'merges listener class overrides with Config defaults' do
          expected_config = retry_config.merge(max_attempts: 7)
          expect(EventPeople::Config.broker).to receive(:consume).with(consumed_event_name, retry_config: expected_config)

          subject
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

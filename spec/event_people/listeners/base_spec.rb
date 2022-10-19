describe EventPeople::Listeners::Base do
  describe '.bind' do
    let(:method_handle) { 'handle' }
    let(:event_name) { 'event_name' }
    let(:app_name) { ENV['RABBIT_EVENT_PEOPLE_APP_NAME'].downcase }
    let(:specific_listener_config) {
      { listener_class: described_class, method: method_handle, routing_key: "#{event_name}.#{app_name}" }
    }
    let(:generic_listener_config) {
      { listener_class: described_class, method: method_handle, routing_key: "#{event_name}.all" }
    }

    subject { described_class.bind(method_handle, event_name) }

    it 'register a new listener on the Manager' do
      expect(EventPeople::Listeners::Manager).to receive(:register_listener_configuration)
        .with(specific_listener_config)
      expect(EventPeople::Listeners::Manager).to receive(:register_listener_configuration)
        .with(generic_listener_config)

      subject
    end

    context 'when event has 3 parts' do
      let(:event_name) { 'resource.origin.action' }

      it 'binds both routing keys to queue' do
        expect(EventPeople::Listeners::Manager).to receive(:register_listener_configuration)
          .with(specific_listener_config)
        expect(EventPeople::Listeners::Manager).to receive(:register_listener_configuration)
          .with(generic_listener_config)

        subject
      end
    end

    context 'when event has 4 parts' do
      let(:event_name) { 'resource.origin.action.destination' }
      let(:specific_listener_config) {
        { listener_class: described_class, method: method_handle, routing_key: 'resource.origin.action.app_name' }
      }

      it 'binds only specific routing keys to queue' do
        expect(EventPeople::Listeners::Manager).to receive(:register_listener_configuration)
          .with(specific_listener_config)

        subject
      end
    end
  end
end

require "spec_helper"

describe EventPeople::Event do
  context 'when body comes from an application' do
    let(:name) { 'omg.lol.bbq' }
    let(:body) { { number: 666, something: "cool" } }
    let(:event) { described_class.new(name, body) }
    let(:schemaVersion) { 1.0 }

    it 'holds the #name value' do
      expect(event.name).to eq 'omg.lol.bbq.all'
    end

    it 'holds the #body value' do
      expect(event.body).to eq number: 666, something: 'cool'
    end

    describe '#payload' do
      let(:payload_expected) do
        {
          headers: {
            appName: EventPeople::Config::APP_NAME,
            resource: 'omg',
            origin: 'lol',
            action: 'bbq',
            destination: 'all',
            schemaVersion:
          },
          body:
        }.to_json
      end

      it 'returns payload value in JSON format' do
        expect(event.payload).to eq payload_expected
      end

      it "add all as destination on event's name" do
        expect(event.name).to eq "#{name}.all"
      end

      context 'with non default schemaVersion' do
        let(:schemaVersion) { 4.2 }
        let(:event) { described_class.new(name, body, schemaVersion) }

        it 'changes default schemaVersion' do
          expect(event.payload).to eq payload_expected
        end
      end

      context 'when name has all 4 parts' do
        let(:name) { 'omg.lol.bbq.destination' }
        let(:payload_expected) do
          {
            headers: {
              appName: EventPeople::Config::APP_NAME,
              resource: 'omg',
              origin: 'lol',
              action: 'bbq',
              destination: 'destination',
              schemaVersion:
            },
            body:
          }.to_json
        end

        it 'returns payload value in JSON format' do
          expect(event.payload).to eq payload_expected
        end

        it "does not change event's name" do
          expect(event.name).to eq name
        end
      end
    end
  end

  context 'when body comes from RabbitMQ' do
    let(:name) { 'omg.lol.bbq' }
    let(:event) { described_class.new(name, body_from_rabbit.to_json) }
    let(:body) { { number: 666, something: 'cool' } }
    let(:schemaVersion) { 1.9 }
    let(:body_from_rabbit) do
      {
        headers: {
          appName: EventPeople::Config::APP_NAME,
          resource: 'omg',
          origin: 'lol',
          action: 'bbq',
          schemaVersion:
        },
        body:
      }
    end

    it 'holds the #name value' do
      expect(event.name).to eq 'omg.lol.bbq.all'
    end

    it 'returns the body inside the body' do
      expect(event.body).to eq JSON.parse(body.to_json)
    end

    describe '#payload' do
      it 'returns payload value in JSON format' do
        expect(event.payload).to eq body_from_rabbit.to_json
      end
    end
  end

  let(:name) { 'omg.lol.bbq' }
  let(:body) { { number: 666, something: 'cool' } }
  let(:event) { described_class.new(name, body) }

  describe '#body?' do
    subject { event.body? }

    context 'when body is nil' do
      let(:body) { nil }

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'when body is empty' do
      let(:body) { {} }

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'when body is present' do
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end
  end

  describe '#name?' do
    subject { event.name? }

    context 'when name is nil' do
      let(:name) { nil }

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'when name is empty' do
      let(:name) { '' }

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'when name is present' do
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end
  end
end

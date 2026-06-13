RSpec.describe EventPeople::Broker::Rabbit::RetryManager do
  let(:default_initial_delay) { EventPeople::Config::DEFAULT_INITIAL_DELAY }

  describe '#should_retry?' do
    it 'returns true when retry_count < max_retries' do
      expect(described_class.new(3).should_retry?(2)).to be true
    end
    it 'returns false when retry_count == max_retries' do
      expect(described_class.new(3).should_retry?(3)).to be false
    end
    it 'returns false when retry_count > max_retries' do
      expect(described_class.new(3).should_retry?(5)).to be false
    end
  end

  describe '#get_next_delay' do
    context 'exponential strategy' do
      subject { described_class.new(3, 'exponential') }

      it 'uses initialDelay * 5^0 for retry 0' do
        expect(subject.get_next_delay(0)).to eq(default_initial_delay)
      end

      it 'uses initialDelay * 5^1 for retry 1' do
        expect(subject.get_next_delay(1)).to eq(default_initial_delay * 5)
      end

      it 'caps at MAX_DELAY' do
        expect(subject.get_next_delay(100)).to eq(described_class::MAX_DELAY)
      end

      context 'when a custom initial_delay is provided' do
        subject { described_class.new(3, 'exponential', initial_delay: 500) }

        it 'uses the custom initial_delay' do
          expect(subject.get_next_delay(0)).to eq(500)
          expect(subject.get_next_delay(1)).to eq(500 * 5)
        end
      end
    end

    context 'fixed strategy' do
      subject { described_class.new(3, 'fixed') }

      it 'always returns the default initial_delay' do
        expect(subject.get_next_delay(0)).to eq(default_initial_delay)
        expect(subject.get_next_delay(5)).to eq(default_initial_delay)
      end

      context 'when a custom initial_delay is provided' do
        subject { described_class.new(3, 'fixed', initial_delay: 250) }

        it 'always returns the custom initial_delay' do
          expect(subject.get_next_delay(0)).to eq(250)
          expect(subject.get_next_delay(5)).to eq(250)
        end
      end
    end
  end
end

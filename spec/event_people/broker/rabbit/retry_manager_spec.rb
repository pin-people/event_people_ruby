RSpec.describe EventPeople::Broker::Rabbit::RetryManager do
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
        expect(subject.get_next_delay(0)).to eq(described_class::INITIAL_DELAY)
      end
      it 'uses initialDelay * 5^1 for retry 1' do
        expect(subject.get_next_delay(1)).to eq(described_class::INITIAL_DELAY * 5)
      end
      it 'caps at MAX_DELAY' do
        expect(subject.get_next_delay(100)).to eq(described_class::MAX_DELAY)
      end
    end

    context 'fixed strategy' do
      subject { described_class.new(3, 'fixed') }
      it 'always returns INITIAL_DELAY' do
        expect(subject.get_next_delay(0)).to eq(described_class::INITIAL_DELAY)
        expect(subject.get_next_delay(5)).to eq(described_class::INITIAL_DELAY)
      end
    end
  end
end

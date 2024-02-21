# frozen_string_literal: true

describe Events::DecisionReviewCreated do
  let!(:consumer_event_id) { "123" }
  let!(:reference_id) { "2001" }
  let!(:completed_event) { DecisionReviewCreatedEvent.create!(reference_id: "999", completed_at: Time.zone.now) }
  let!(:event) { instance_double(Event) }

  describe "#event_exists_and_is_completed?" do
    subject { described_class.event_exists_and_is_completed?(consumer_event_id) }

    context "When there is no previous Event" do
      it "should return false" do
        expect(subject).to be_falsey
      end
    end

    context "Where there is a previous Event that was completed" do
      it "should return true" do
        expect(Events::DecisionReviewCreated.event_exists_and_is_completed?("999")).to be_truthy
      end
    end
  end

  describe "#create!" do
    subject { described_class.create!(consumer_event_id, reference_id) }

    context "when lock acquisition fails" do
      before do
        allow(RedisMutex).to receive(:with_lock).and_raise(RedisMutex::LockError)
      end

      it "logs the error message" do
        expect(Rails.logger).to receive(:error)
          .with("Failed to acquire lock for Claim ID: #{reference_id}! This Event is being"\
                " processed. Please try again later.")
        subject
      end
    end

    context "when lock Key is already in the Redis Cache" do
      it "throws a RedisLockFailed error" do
        redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
        lock_key = "RedisMutex:EndProductEstablishment:#{reference_id}"
        redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)
        expect { subject }.to raise_error(Caseflow::Error::RedisLockFailed)
        redis.del(lock_key)
      end
    end

    context "when creation is successful" do
      it "should create a new Event instance" do
        subject
        expect(Event.where(reference_id: consumer_event_id).exists?).to eq(true)
      end
    end

    context 'when a StandardError occurs' do
      let(:error_message) { 'StandardError message' }

      before do
        allow(DecisionReviewCreatedEvent).to receive(:create).and_raise(StandardError, error_message)
        allow(Event).to receive(:find_by).and_return(event)
        allow(event).to receive(:update!)
      end

      it 'logs the error and updates the event' do
        expect(Rails.logger).to receive(:error).with(error_message)
        expect(event).to receive(:update!).with(error: error_message, info: { "failed_claim_id" => reference_id })

        expect { subject.create!(consumer_event_id, reference_id) }.to raise_error(StandardError)
      end
    end
  end
end

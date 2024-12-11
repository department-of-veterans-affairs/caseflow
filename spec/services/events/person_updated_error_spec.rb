# frozen_string_literal: true

describe Events::PersonUpdatedError do
  let!(:consumer_event_id) { SecureRandom.uuid }
  let!(:errored_participant_id) { "999" }
  let!(:error_message) { "The PersonUpdate had an error" }

  describe "#handle_service_error" do
    subject { described_class.new(consumer_event_id, errored_participant_id, error_message) }

    context "When Person Update Error is Saved in Caseflow" do
      it "should create a new event with an updated Error" do
        return_value = subject.call

        new_event = Event.find_by(reference_id: consumer_event_id)

        expect(return_value).to eq(:created)
        expect(new_event).to be_kind_of(PersonUpdatedErrorEvent)
        expect(new_event.reference_id).to eq(consumer_event_id)
        expect(new_event.error).to eq(error_message)
        expect(new_event.info).to eq("errored_claim_id" => "999")
        expect(new_event.errored_claim_id).to eq(errored_participant_id)
      end
    end

    context "when event already exists" do
      before do
        PersonUpdatedErrorEvent.create!(reference_id: consumer_event_id)
      end

      it "should create a new event with an updated Error" do
        return_value = subject.call

        expect(return_value).to eq(:updated)
      end
    end

    context "when lock acquisition fails" do
      before do
        allow(RedisMutex).to receive(:with_lock).and_raise(RedisMutex::LockError)
      end

      it "logs the error message" do
        expect(Rails.logger).to receive(:error)
          .with("LockError occurred: RedisMutex::LockError")

        expect { subject.call }.to raise_error(Caseflow::Error::RedisLockFailed)
      end
    end

    context "when standard error is raised" do
      it "logs an error and raises if an standard error occurs" do
        allow_any_instance_of(PersonUpdatedErrorEvent).to receive(:update!).and_raise(StandardError)
        expect { subject.call }.to raise_error(StandardError)
      end
    end

    context "when Redis key exists" do
      let!(:redis_lock_failed) { Caseflow::Error::RedisLockFailed }
      it "logs error message that Redis key exists" do
        redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
        lock_key = "RedisMutex:PersonUpdatedError:#{consumer_event_id}"
        redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)
        expect { subject.call }.to raise_error(redis_lock_failed)
      end
    end
  end
end

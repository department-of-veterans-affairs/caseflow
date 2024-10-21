# frozen_string_literal: true

describe Events::DecisionReviewCreated do
  let!(:consumer_event_id) { "123" }
  let!(:event) { instance_double(Event) }
  let!(:claim_id) { "2001" }
  let(:event_created) { DecisionReviewCreatedEvent.create!(reference_id: consumer_event_id, completed_at: nil) }
  let!(:completed_event) { DecisionReviewCreatedEvent.create!(reference_id: "999", completed_at: Time.zone.now) }
  let!(:json_payload) { read_json_payload }
  let!(:headers) { sample_headers }
  let!(:parser) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example }
  let!(:params) { { consumer_event_id: consumer_event_id, claim_id: claim_id } }

  describe "#create!" do
    subject { described_class.create!(params, headers, read_json_payload) }

    context "When event is completed info field returns to default state" do
      it "event field is only payload" do
        subject # runs and completes the process
        completed = DecisionReviewCreatedEvent.find_by(reference_id: consumer_event_id)
        expect(completed.info).to eq({ "event_payload" => json_payload })
      end
    end

    # codeclimate:disable DuplicatedCode
    context "when lock acquisition fails" do
      before do
        allow(RedisMutex).to receive(:with_lock).and_raise(RedisMutex::LockError)
      end

      it "logs the error message" do
        expect(Rails.logger).to receive(:error)
          .with("Failed to acquire lock for Claim ID: #{claim_id}! This Event is being"\
                " processed. Please try again later.")
        expect { subject }.to raise_error(RedisMutex::LockError)
      end
    end

    # codeclimate:disable DuplicatedCode
    context "when lock Key is already in the Redis Cache" do
      it "throws a RedisLockFailed error" do
        redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
        lock_key = "RedisMutex:EndProductEstablishment:#{claim_id}"
        redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)
        expect { subject }.to raise_error(Caseflow::Error::RedisLockFailed)
        redis.del(lock_key)
      end
    end
    # codeclimate:enable DuplicatedCode

    context "when creation is successful" do
      it "should create a new Event instance" do
        subject
        expect(Event.where(reference_id: consumer_event_id).exists?).to eq(true)
      end

      it "should call all sub services" do
        expect(Events::DecisionReviewCreated::DecisionReviewCreatedParser).to receive(:new)
          .with(headers, json_payload).and_call_original
        expect(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event)
          .with(event: event_created, css_id: parser.css_id, station_id: parser.station_id).and_call_original
        expect(Events::DecisionReviewCreated::CreateClaimReview).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::UpdateVacolsOnOptin).to receive(:process!).and_call_original
        expect(Events::CreateClaimantOnEvent).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::CreateIntake).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::CreateEpEstablishment).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::CreateRequestIssues).to receive(:process!).and_call_original
        subject
      end
    end

    context "when a StandardError occurs" do
      let(:standard_error) { StandardError.new("Lions, tigers, and bears, OH MY!") }

      before do
        allow(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event).and_raise(standard_error)
        allow(Rails.logger).to receive(:error)
      end

      it "the error is logged" do
        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include(standard_error.message)
        end
        expect { described_class.create!(params, headers, read_json_payload) }
          .to raise_error(StandardError)
      end

      it "logs the error and updates the event" do
        expect(Rails.logger).to receive(:error).with(/#{standard_error}/)

        expect { described_class.create!(params, headers, read_json_payload) }.to raise_error(StandardError)
      end

      it "records an error at the event level" do
        expect { described_class.create!(params, headers, read_json_payload) }
          .to raise_error(standard_error)
        event = DecisionReviewCreatedEvent.find_by(reference_id: consumer_event_id)
        expect(event.error).to eq("#{standard_error.class} : #{standard_error.message}")
        expect(event.info["failed_claim_id"]).to eq(claim_id)
        expect(event.info["error"]).to eq(standard_error.message)
        expect(event.info["error_class"]).to eq("StandardError")
        expect(event.info["error_backtrace"]).to be_present
      end
    end
  end
end

def read_json_payload
  JSON.parse(File.read(Rails.root.join("app",
                                       "services",
                                       "events",
                                       "decision_review_created",
                                       "decision_review_created_example.json")))
end

def sample_headers
  {
    "X-VA-Vet-SSN" => "123456789",
    "X-VA-File-Number" => "77799777",
    "X-VA-Vet-First-Name" => "John",
    "X-VA-Vet-Last-Name" => "Smith",
    "X-VA-Vet-Middle-Name" => "Alexander"
  }
end

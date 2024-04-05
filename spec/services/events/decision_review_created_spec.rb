# frozen_string_literal: true

describe Events::DecisionReviewCreated do
  let!(:consumer_event_id) { "123" }
  let!(:event) { instance_double(Event) }
  let!(:reference_id) { "2001" }
  let(:event_created) { DecisionReviewCreatedEvent.create!(reference_id: consumer_event_id, completed_at: nil) }
  let!(:completed_event) { DecisionReviewCreatedEvent.create!(reference_id: "999", completed_at: Time.zone.now) }
  let!(:json_payload) { read_json_payload }
  let!(:headers) { sample_headers }
  let!(:parser) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example}


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
    subject { described_class.create!(consumer_event_id, reference_id, headers, read_json_payload) }

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

      it "should call all sub services" do
        expect(Events::DecisionReviewCreated::DecisionReviewCreatedParser).to receive(:new).with(headers, json_payload).and_call_original
        expect(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event).with(event: event_created, parser: parser.css_id, parser.station_id).and_call_original
        expect(Events::DecisionReviewCreated::CreateClaimReview).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::UpdateVacolsOnOptin).to receive(:process!).and_call_original
        expect(Events::CreateClaimantOnEvent).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::CreateIntake).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::CreateEpEstablishment).to receive(:process!).and_call_original
        expect(Events::DecisionReviewCreated::CreateRequestIssues).to receive(:process!).and_call_original
        subject
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

def read_json_payload
JSON.generate(JSON.parse(File.read(Rails.root.join("app",
                                                   "services",
                                                   "events",
                                                   "decision_review_created",
                                                   "decision_review_created_example.json"))))
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

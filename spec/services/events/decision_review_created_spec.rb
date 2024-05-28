# frozen_string_literal: true

describe Events::DecisionReviewCreated do
  let!(:consumer_event_id) { "123" }
  let!(:event) { instance_double(Event) }
  let!(:reference_id) { "2001" }
  let(:event_created) { DecisionReviewCreatedEvent.create!(reference_id: consumer_event_id, completed_at: nil) }
  let!(:completed_event) { DecisionReviewCreatedEvent.create!(reference_id: "999", completed_at: Time.zone.now) }
  let!(:json_payload) { read_json_payload }
  let!(:headers) { sample_headers }
  let!(:parser) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example }

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
        expect { described_class.create!(consumer_event_id, reference_id, headers, json_payload) }
          .to raise_error(StandardError)
      end

      it "logs the error and updates the event" do
        expect(Rails.logger).to receive(:error).with(/#{standard_error}/)

        expect { subject.create!(consumer_event_id, reference_id) }.to raise_error(StandardError)
      end
    end
  end

  describe "#process_nonrating" do
    let(:payload_with_valid_issue) do
      {
        request_issues: [
          {
            nonrating_issue_category: "Disposition",
            contested_decision_issue_id: 1
          }
        ]
      }
    end

    let(:payload_with_invalid_issue) do
      {
        request_issues: [
          {
            nonrating_issue_category: "Other",
            contested_decision_issue_id: nil
          }
        ]
      }
    end

    let(:payload_with_unknown_issue) do
      {
        request_issues: [
          {
            nonrating_issue_category: "Disposition",
            contested_decision_issue_id: 2
          }
        ]
      }
    end

    before do
      create(:decision_issue, id: 1)
      create(:request_issue, contested_decision_issue_id: 1, nonrating_issue_category: "Valid Category")
    end

    it "sets the nonrating_issue_category from the database when there is exactly one matching issue" do
      described_class.process_nonrating(payload_with_valid_issue)
      expect(payload_with_valid_issue[:request_issues].first[:nonrating_issue_category]).to eq("Valid Category")
    end

    it "sets the nonrating_issue_category to 'Unknown Issue Category' when there are multiple matching issues" do
      create(:request_issue, contested_decision_issue_id: 1, nonrating_issue_category: "Another Valid Category")
      described_class.process_nonrating(payload_with_valid_issue)
      expect(payload_with_valid_issue[:request_issues].first[:nonrating_issue_category]).to eq("Unknown Issue Category")
    end

    it "sets the nonrating_issue_category to 'Unknown Issue Category' when the issue is invalid" do
      described_class.process_nonrating(payload_with_invalid_issue)
      expect(payload_with_invalid_issue[:request_issues].first[:nonrating_issue_category]).to eq("Unknown Issue Category")
    end

    it "sets the nonrating_issue_category to 'Unknown Issue Category' when the contested_decision_issue_id is not found" do
      described_class.process_nonrating(payload_with_unknown_issue)
      expect(payload_with_unknown_issue[:request_issues].first[:nonrating_issue_category]).to eq("Unknown Issue Category")
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

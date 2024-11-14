# frozen_string_literal: true

describe Events::DecisionReviewCompleted do
  let(:consumer_event_id) { "1234567890" }
  let(:claim_id) { "12201" }
  let(:event) { DecisionReviewCompletedEvent.new(reference_id: consumer_event_id) }
  let(:parser) do
    double(
      "Parser",
      css_id: "css_id",
      station_id: "station_id",
      end_product_establishment_reference_id: "ep_ref_id"
    )
  end
  let(:review) { double("Review", reference_id: "1234567890") }
  let(:params) { { consumer_event_id: consumer_event_id, claim_id: claim_id } }
  let(:headers) { {} }
  let(:payload) { {} }
  let(:user) { double("User") }
  let(:end_product_establishment) do
    double("EndProductEstablishment", source: review)
  end
  subject { described_class.complete!(params, headers, payload) }

  before do
    allow(DecisionReviewCompletedEvent).to receive(:find_or_create_by)
      .with(reference_id: consumer_event_id).and_return(event)
    allow(Events::DecisionReviewCompleted::DecisionReviewCompletedParser).to receive(:new)
      .with(headers, payload).and_return(parser)
    allow(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event)
      .with(event: event, css_id: parser.css_id, station_id: parser.station_id).and_return(user)
    allow(EndProductEstablishment).to receive(:find_by)
      .with(reference_id: parser.end_product_establishment_reference_id).and_return(end_product_establishment)
    allow(Events::DecisionReviewCompleted::CompleteClaimReview).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(Events::DecisionReviewCompleted::CompleteEndProductEstablishment).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(DecisionIssuesCompleteEvent).to receive(:new)
      .with(user: user, review: review, parser: parser, event: event, epe: end_product_establishment)
      .and_return(double("DecisionIssuesCompleteEvent", perform!: nil))
  end

  describe ".Complete!" do
    subject { described_class.complete!(params, headers, payload) }

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

    context "when lock Key is already in the Redis Cache" do
      it "throws a RedisLockFailed error" do
        redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
        lock_key = "RedisMutex:EndProductEstablishment:#{claim_id}"
        redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)
        expect { subject }.to raise_error(Caseflow::Error::RedisLockFailed)
        redis.del(lock_key)
      end
    end

    it "completes claim review" do
      expect(Events::DecisionReviewCompleted::CompleteClaimReview).to receive(:process!)
        .with(event: event, parser: parser)
      subject
    end

    it "completes request issues" do
      expect(DecisionIssuesCompleteEvent).to receive(:new)
        .with(user: user, review: review, parser: parser, event: event, epe: end_product_establishment)
        .and_return(double("DecisionIssuesCompleteEvent", perform!: nil))
      subject
    end
  end
end

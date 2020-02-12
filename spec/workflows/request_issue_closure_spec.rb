# frozen_string_literal: true

describe RequestIssueClosure, :postgres do
  let(:decision_review) { create(:higher_level_review) }
  let(:end_product_establishment) { nil }
  let(:closed_status) { nil }
  let(:closed_at) { nil }

  let(:request_issue) do
    create(
      :request_issue,
      decision_review: decision_review,
      end_product_establishment: end_product_establishment,
      closed_status: closed_status,
      closed_at: closed_at
    )
  end
  let(:request_issue_closure) { RequestIssueClosure.new(request_issue) }

  context "with_no_decision!" do
    subject { request_issue_closure.with_no_decision! }

    context "end product is cleared" do
      let(:end_product_establishment) { create(:end_product_establishment, :cleared) }

      it "closes the request issue and cancels decision issue sync" do
        subject

        expect(request_issue.closed_status).to eq("no_decision")
        expect(request_issue.closed_at).to be_within(1.second).of Time.zone.now
        expect(request_issue.decision_sync_canceled_at).to be_within(1.second).of Time.zone.now
      end

      context "request issue is already closed" do
        let(:closed_status) { "removed" }
        let(:closed_at) { 2.days.ago }

        it { is_expected.to be_falsey }
      end

      context "the request issue contention has a disposition" do
        before { allow_any_instance_of(RequestIssue).to receive(:contention_disposition).and_return(true) }

        it { is_expected.to be_falsey }
      end
    end

    context "end product is not cleared" do
      let(:end_product_establishment) { create(:end_product_establishment, :active) }

      it { is_expected.to be_falsey }
    end
  end
end

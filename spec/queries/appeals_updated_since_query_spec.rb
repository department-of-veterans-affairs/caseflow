# frozen_string_literal: true

describe AppealsUpdatedSinceQuery, :postgres do
  before do
    Timecop.freeze(post_ama_start_date)
  end

  let(:since_date) { Time.zone.now }
  let!(:old_appeal) { create(:appeal, number_of_claimants: 0, updated_at: since_date - 1.hour) }

  describe "#call" do
    subject { described_class.new(since_date: since_date).call }

    context "Appeal updated_at since" do
      let!(:appeal) { create(:appeal, updated_at: since_date + 1.hour) }

      it "returns 1 Appeal" do
        expect(subject).to eq([appeal])
      end
    end

    context "Request Issue updated_at since" do
      let!(:request_issue) { create(:request_issue, decision_review: old_appeal, updated_at: since_date + 1.hour) }

      it "returns 1 Appeal" do
        expect(subject).to eq([old_appeal])
      end
    end
  end
end

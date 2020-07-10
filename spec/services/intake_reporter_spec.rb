# frozen_string_literal: true

describe IntakeReporter do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  describe "#report" do
    context "one type each of decision review" do
      let(:hlr) { create(:higher_level_review) }
      let(:sc) { create(:supplemental_claim) }
      let(:appeal) { create(:appeal) }
      let!(:hlr_intake) { create(:intake, :completed, detail: hlr, completed_at: Time.zone.now + 10.minutes) }
      let!(:sc_intake) { create(:intake, :completed, detail: sc, completed_at: Time.zone.now + 10.minutes) }
      let!(:appeal_intake) { create(:intake, :completed, detail: appeal, completed_at: Time.zone.now + 10.minutes) }

      let!(:hlr_rating_issue) { create(:request_issue, :rating, decision_review: hlr) }
      let!(:sc_nonrating_issue) { create(:request_issue, :nonrating, decision_review: sc) }
      let!(:appeal_rating_decision) { create(:request_issue, :rating_decision, decision_review: appeal) }

      subject do
        described_class.new(type: decision_review_type, start_date: Time.zone.yesterday, end_date: Time.zone.tomorrow)
      end

      context "HLR" do
        let(:decision_review_type) { "HigherLevelReview" }

        it "returns hash summary" do
          report = subject.report

          expect(report).to eq(
            rating_issue: 1,
            rating_decision: 0,
            nonrating: 0,
            decision_issue: 0,
            unidentified: 0,
            ineligible: 0,
            median_intake_time: 600.0
          )
        end
      end

      context "SC" do
        let(:decision_review_type) { "SupplementalClaim" }

        it "returns hash summary" do
          report = subject.report

          expect(report).to eq(
            rating_issue: 0,
            rating_decision: 0,
            nonrating: 1,
            decision_issue: 0,
            unidentified: 0,
            ineligible: 0,
            median_intake_time: 600.0
          )
        end
      end

      context "Appeal" do
        let(:decision_review_type) { "Appeal" }

        it "returns hash summary" do
          report = subject.report

          expect(report).to eq(
            rating_issue: 0,
            rating_decision: 1,
            nonrating: 0,
            decision_issue: 0,
            unidentified: 0,
            ineligible: 0,
            median_intake_time: 600.0
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

describe DirectReviewDocket, :postgres do
  before do
    create(:case_distribution_lever, :ama_direct_review_docket_time_goals)
    create(:case_distribution_lever, :ama_direct_review_start_distribution_prior_to_goals)
  end
  context "#docket_type" do
    subject { DirectReviewDocket.new.docket_type }
    it "returns the correct docket type" do
      expect(subject).to eq(Constants.AMA_DOCKETS.direct_review)
    end
  end

  context "#due_count" do
    subject { DirectReviewDocket.new.due_count }

    before do
      Timecop.freeze(Date.new(2021, 2, 19))

      (295..304).each do |i|
        appeal = create(:appeal,
                        :with_post_intake_tasks,
                        docket_type: Constants.AMA_DOCKETS.direct_review,
                        receipt_date: i.days.ago)
        appeal.set_target_decision_date!
      end
    end

    it "returns the expected count" do
      expect(subject).to eq(10)
    end
  end

  context "#nonpriority_receipts_per_year" do
    subject { DirectReviewDocket.new.nonpriority_receipts_per_year }

    context "before Feb 29th, 2020" do
      before do
        # 364 days after March 1st 2019
        Timecop.freeze(Date.new(2020, 2, 28))
        100.times do
          create(:appeal,
                 docket_type: Constants.AMA_DOCKETS.direct_review,
                 receipt_date: Date.new(2019, 11, 28))
        end
      end

      it "returns weighted number of appeals" do
        expect(subject).to eq(((100 * 365) / 364).round)
      end
    end

    context "after Feb 29th, 2020" do
      before do
        Timecop.freeze(Date.new(2022, 2, 28))
        5.times do
          create(:appeal,
                 docket_type: Constants.AMA_DOCKETS.direct_review,
                 receipt_date: Date.new(2021, 1, 1))
        end
        5.times do
          create(:appeal,
                 docket_type: Constants.AMA_DOCKETS.direct_review,
                 receipt_date: Date.new(2021, 4, 1))
        end
      end

      it "returns number of appeals in the last year" do
        expect(subject).to eq(5)
      end
    end
  end
end

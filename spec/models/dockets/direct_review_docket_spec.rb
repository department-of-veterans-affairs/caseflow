describe DirectReviewDocket do
  before do
    FeatureToggle.enable!(:ama_auto_case_distribution)
  end

  after do
    FeatureToggle.disable!(:ama_auto_case_distribution)
  end

  context "#due_count" do
    subject { DirectReviewDocket.new.due_count }

    before do
      Timecop.freeze(Date.new(2021, 2, 19))

      (300..309).each do |i|
        appeal = create(:appeal,
                        :with_tasks,
                        docket_type: "direct_review",
                        receipt_date: i.days.ago)
        appeal.set_target_decision_date!
      end
    end

    it "returns the expected count" do
      expect(subject).to eq(5)
    end
  end

  context "#time_until_due_of_oldest_appeal" do
    subject { DirectReviewDocket.new.time_until_due_of_oldest_appeal }

    before do
      Timecop.freeze(Date.new(2020, 2, 19))

      (102..105).each do |i|
        appeal = create(:appeal,
                        :with_tasks,
                        docket_type: "direct_review",
                        receipt_date: i.days.ago)
        appeal.set_target_decision_date!
      end
    end

    it "returns the time until due" do
      expect(subject).to eq(200)
    end
  end

  context "#nonpriority_receipts_per_year" do
    subject { DirectReviewDocket.new.nonpriority_receipts_per_year }

    context "before April 1st, 2019" do
      before { Timecop.freeze(Date.new(2019, 3, 30)) }

      it "returns baseline" do
        expect(subject).to eq(38_500)
      end
    end

    context "before Feb 29th, 2020" do
      before do
        # 364 days after March 1st 2019
        Timecop.freeze(Date.new(2020, 2, 28))
        100.times { create(:appeal, docket_type: "direct_review", receipt_date: Date.new(2019, 11, 28)) }
      end

      it "returns weighted number of appeals" do
        expect(subject).to eq(((100 * 365) / 364).round)
      end
    end

    context "after Feb 29th, 2020" do
      before do
        Timecop.freeze(Date.new(2022, 2, 28))
        5.times { create(:appeal, docket_type: "direct_review", receipt_date: Date.new(2021, 1, 1)) }
        5.times { create(:appeal, docket_type: "direct_review", receipt_date: Date.new(2021, 4, 1)) }
      end

      it "returns number of appeals in the last year" do
        expect(subject).to eq(5)
      end
    end
  end
end

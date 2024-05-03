# frozen_string_literal: true

describe UpdateAppealAffinityDatesJob do
  context "#distirbuted_cases_to_receipt_date" do
    it "deletes the docket/priority pairs which will never need affinities" do
    end
  end

  context "#latest_receipt_dates" do
    context "from_distribution" do
      it "does not use DistributeCases from any push job" do
      end
    end

    context "from_push_job" do
      it "only uses DistributedCases from the most recent push job" do
      end
    end
  end

  context "#process_ama_appeals_which_need_affinity_updates" do
    let(:hashes_array) do
      [{ docket: "hearing", priority: true, receipt_date: Time.zone.now },
       { docket: "direct_review", priority: true, receipt_date: Time.zone.now },
       { docket: "legacy", priority: true, receipt_date: Time.zone.now }]
    end

    it "doesn't process any legacy appeals" do
      expect_any_instance_of(described_class).to receive(:create_or_update_appeal_affinities).exactly(2).times
      subject.send(:process_ama_appeals_which_need_affinity_updates, hashes_array)
    end
  end

  context "#create_or_update_appeal_affinties" do
    it "updates existing affinity records if they exist" do
    end

    it "creates new affinity records if they don't exist" do
    end
  end

  context "#perform" do
    it "updates from distribution if provided a distribution_id" do
      expect_any_instance_of(described_class).to receive(:update_from_requested_distribution).and_return(true)
      described_class.new(1).perform_now
    end

    it "updates from the most recent push job if provided no args" do
      expect_any_instance_of(described_class).to receive(:update_from_push_priority_appeals_job).and_return(true)
      described_class.new.perform_now
    end

    it "sends a slack notification if the job errors" do
      allow_any_instance_of(described_class)
        .to receive(:update_from_push_priority_appeals_job).and_raise(StandardError)

      expect_any_instance_of(SlackService).to receive(:send_notification)

      described_class.new.perform_now
    end
  end
end

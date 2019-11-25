# frozen_string_literal: true

describe NightlySyncsJob, :all_dbs do
  context "when the job runs successfully" do
    before do
      5.times { create(:staff) }
    end

    subject { described_class.perform_now }

    it "updates cached_user_attributes table" do
      subject

      expect(CachedUser.count).to eq(5)
    end

    it "updates DataDog" do
      emitted_gauges = []
      allow(DataDogService).to receive(:emit_gauge) do |args|
        emitted_gauges.push(args)
      end

      subject

      expect(emitted_gauges).to include(
        app_name: "caseflow_job",
        metric_group: "nightly_syncs_job",
        metric_name: "runtime",
        metric_value: anything
      )
    end
  end
end

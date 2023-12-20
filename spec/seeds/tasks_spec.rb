# frozen_string_literal: true

describe Seeds::Tasks, :all_dbs do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      # to do: these are expensive to run, esp Facols.
      # make Seeds::Tasks less dependent on them.
      Seeds::Users.new.seed!
      puts "start facols seed #{Time.zone.now}"
      Seeds::Facols.new.seed!
      puts "end facols seed #{Time.zone.now}"
    end

    it "creates all kinds of appeals and tasks" do
      expect { subject }.to_not raise_error
      expect(Task.count).to be > 500 # to do: get rid of rand-based logic
      expect(Appeal.count).to be > 200
    end

    describe "seeding hpr tasks" do
      it "created hpr tasks for ama appeals" do
        described_class.new.send(:create_ama_hpr_tasks)
        expect(HearingPostponementRequestMailTask.where(appeal_type: "Appeal").count).to be >= 20
      end

      it "created hpr tasks for legacy appeals" do
        described_class.new.send(:create_legacy_hpr_tasks)
        expect(HearingPostponementRequestMailTask.where(appeal_type: "LegacyAppeal").count).to be >= 20
      end
    end

    describe "seeding hwr tasks" do
      it "created hwr tasks for ama appeals" do
        described_class.new.send(:create_ama_hwr_tasks)
        expect(HearingWithdrawalRequestMailTask.where(appeal_type: "Appeal").count).to be >= 20
      end

      it "created hwr tasks for legacy appeals" do
        described_class.new.send(:create_legacy_hwr_tasks)
        expect(HearingWithdrawalRequestMailTask.where(appeal_type: "LegacyAppeal").count).to be >= 20
      end
    end
  end
end

# frozen_string_literal: true

describe ETL::UnknownStatusWithOpenRootTaskQuery, :etl, :all_dbs do
  let!(:unknown_appeal) do
    create(:appeal, :with_post_intake_tasks).tap do |appeal|
      root_task = appeal.root_task
      appeal.tasks.open.each { |task| task.completed! unless task == root_task }
      create(:bva_dispatch_task, :cancelled, parent: root_task)
      create(:informal_hearing_presentation_task, :assigned, parent: root_task)
    end
  end

  before do
    ETL::Builder.new.full
  end

  describe "#call" do
    subject { described_class.new.call }

    it "returns array of matching appeals" do
      etl_appeal = ETL::Appeal.find_by(appeal_id: unknown_appeal.id)
      expect(subject).to eq([etl_appeal])
    end
  end
end

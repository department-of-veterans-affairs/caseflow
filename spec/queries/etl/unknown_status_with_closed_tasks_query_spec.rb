# frozen_string_literal: true

describe ETL::UnknownStatusWithClosedTasksQuery, :etl, :all_dbs do
  let!(:unknown_appeal) do
    create(:appeal).tap do |appeal|
      root_task = create(:root_task, appeal: appeal)
      create(:bva_dispatch_task, :completed, parent: root_task)
      root_task.completed!
    end
  end

  before do
    ETL::Builder.new.full
  end

  describe "#call" do
    subject { described_class.new.call }

    it "returns array of matching appeals" do
      etl_appeal = ETL::Appeal.find_by(appeal_id: unknown_appeal.id)
      etl_appeal.update!(status: "UNKNOWN")
      expect(subject).to eq([etl_appeal])
    end
  end
end

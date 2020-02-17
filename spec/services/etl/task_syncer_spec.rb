# frozen_string_literal: true

describe ETL::TaskSyncer, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new.call(etl_build) }

    context "BVA status distribution" do
      it "has expected distribution" do
        subject

        expect(Task.count).to eq(31)
        expect(ETL::Task.count).to eq(31)
      end
    end

    context "orphaned Task" do
      let!(:orphaned_task) { create(:task) }
      before do
        orphaned_task.appeal.delete # not destroy, to avoid callbacks
      end

      it "skips orphans" do
        etl_build_table = subject

        expect(Task.count).to eq(32)
        expect(ETL::Task.count).to eq(31)
        expect(etl_build_table).to be_complete
        expect(etl_build_table.rows_rejected).to eq(1)
        expect(etl_build_table.rows_inserted).to eq(31)
        expect(etl_build_table.rows_updated).to eq(0)
      end
    end
  end
end

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

        expect(ETL::Task.count).to eq(31)
      end
    end

    context "orphaned Task" do
      let!(:orphaned_task) { create(:task) }
      before do
        orphaned_task.appeal.delete # not destroy, to avoid callbacks
      end

      it "skips orphans" do
        subject

        expect(ETL::Task.count).to eq(31)
      end
    end
  end
end

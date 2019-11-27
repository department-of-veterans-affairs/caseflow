# frozen_string_literal: true

describe ETL::TaskSyncer, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  describe "#call" do
    subject { described_class.new.call }

    context "BVA status distribution" do
      it "has expected distribution" do
        subject

        expect(ETL::Task.count).to eq(31)
      end
    end
  end
end

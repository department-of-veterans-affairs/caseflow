# frozen_string_literal: true

describe ETL::AppealSyncer, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  describe "#call" do
    subject { described_class.new.call }

    context "BVA status distribution" do
      it "has expected distribution" do
        subject

        expect(ETL::Appeal.count).to eq(13)
      end
    end
  end
end

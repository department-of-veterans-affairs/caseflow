# frozen_string_literal: true

describe ETL::UnknownStatusWithOpenChildTaskQuery, :etl, :all_dbs do
  include_context "ETL Unknown Status Query"

  describe "#call" do
    it_behaves_like "an ETL Unknown status query" do
      subject { described_class.new("InformalHearingPresentationTask").call }
    end
  end
end

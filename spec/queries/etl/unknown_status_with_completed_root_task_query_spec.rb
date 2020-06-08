# frozen_string_literal: true

describe ETL::UnknownStatusWithCompletedRootTaskQuery, :etl, :all_dbs do
  include_context "ETL Query"

  describe "#call" do
    it_behaves_like "an ETL Unknown status query" do
      subject { described_class.new.call }
    end
  end
end

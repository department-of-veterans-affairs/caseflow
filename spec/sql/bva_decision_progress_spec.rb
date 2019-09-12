# frozen_string_literal: true

require "support/database_cleaner"

describe "BVA Decision Progress report", :postgres do
  include SQLHelpers

  context "one row for each category" do
    let(:expected_report) do


    end

    it "generates correct report" do
      expect_sql("bva-decision-progress").to eq(expected_report)
    end
  end
end

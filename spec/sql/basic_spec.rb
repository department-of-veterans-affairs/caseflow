# frozen_string_literal: true

require "support/database_cleaner"

describe "Basic SQL Snippet Library Test", :postgres do
  include SQLHelpers

  context "one Appeal exists" do
    let!(:appeal) { create(:appeal) }

    it "runs SQL" do
      expect_sql("basic_appeal").to eq([appeal.as_hash])
    end
  end
end

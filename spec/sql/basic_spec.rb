# frozen_string_literal: true

describe "Basic SQL Snippet Library Test", :postgres do
  include SQLHelpers

  context "one Appeal exists" do
    let!(:appeal) { create(:appeal) }

    it "runs SQL" do
      expect_sql("basic_appeal").to eq([appeal.as_hash])
    end
  end

  context "one Appeal exists with 2f precision milliseconds" do
    let!(:appeal) { create(:appeal, established_at: Time.utc(2010, 3, 30, 5, 43, "25.12".to_r)) }

    it "rounds correctly" do
      expect_sql("basic_appeal").to eq([appeal.as_hash])
    end
  end
end

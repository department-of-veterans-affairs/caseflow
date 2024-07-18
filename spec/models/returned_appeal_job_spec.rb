# frozen_string_literal: true

RSpec.describe CaseDistributionLever, :all_dbs do
  describe "factory" do
    it "is valid" do
      expect(build(:returned_appeal_job)).to be_valid
    end
  end
end

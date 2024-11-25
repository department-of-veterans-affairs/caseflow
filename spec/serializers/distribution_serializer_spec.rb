# frozen_string_literal: true

describe DistributionSerializer, :all_dbs do
  let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
  let(:distribution) { create(:distribution, :completed, judge: judge) }

  before { Seeds::CaseDistributionLevers.new.seed! }

  subject { DistributionSerializer.new(distribution).as_json }

  context "when in higher environments" do
    before { Rails.env = "prod" }
    after { Rails.env = "test" }

    it "does not incude associated distribution_stats" do
      expect(subject[:distribution_stats]).to be nil
    end
  end

  context "when in lower environments" do
    it "includes associated distribution_stats" do
      expect(subject[:distribution_stats]).to_not be nil
    end
  end
end

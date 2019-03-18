# frozen_string_literal: true

describe UserReporter do
  let!(:user_UC) { create(:user, css_id: "FOOBAR") }
  let!(:user_dc) { create(:user, css_id: "foobar") }

  describe "#report" do
    it "includes all users regardless of case" do
      reporter = described_class.new("foobar")
      expect(reporter.report).to eq([])
      expect(reporter.user_ids).to include(user_UC.id, user_dc.id)
    end
  end

  describe ".models_with_user_id" do
    it "memoizes array of model constants" do
      reporter = described_class.new("foobar")
      reporter.report
      expect(described_class.models_with_user_id).to include(Intake)
    end
  end
end

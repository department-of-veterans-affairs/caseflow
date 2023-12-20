# frozen_string_literal: true

describe Seeds::TestCaseData, :all_dbs do
  describe "#seed!" do
    before do
      create(:veteran, file_number: 400_000_001)
    end
    subject { described_class.new.seed! }

    it "creates test case data from file" do
      expect { subject }.to_not raise_error
      expect(VACOLS::Case.all.count).to be >= 5
      expect(VACOLS::Correspondent.all.count).to be >= 5
    end
  end
end

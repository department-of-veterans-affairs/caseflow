# frozen_string_literal: true

describe Seeds::Correspondence do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before { Seeds::Correspondence.new.seed! }

    it "creates correspondences" do
      expect {subject}.to_not raise_error
    end
  end
end

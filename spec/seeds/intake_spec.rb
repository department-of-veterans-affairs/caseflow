# frozen_string_literal: true

describe Seeds::Intake do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of decision reviews" do
      expect { subject }.to_not raise_error
      expect(HigherLevelReview.count).to eq(7)
    end
  end
end     

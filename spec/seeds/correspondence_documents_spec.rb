# frozen_string_literal: true

describe Seeds::CorrespondenceDocuments do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of correspondence documents" do
      expect { subject }.to_not raise_error
      expect(subject.count).to be_positive
    end
  end
end

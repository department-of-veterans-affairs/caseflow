# frozen_string_literal: true

describe Seeds::Annotations do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of annotations" do
      expect { subject }.to_not raise_error
    end
  end
end

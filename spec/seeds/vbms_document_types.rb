# frozen_string_literal: true

describe Seeds::VbmsDocumentTypes do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of vbms doc types" do
      expect { subject }.to_not raise_error
      expect(subject.count).to be_positive
    end
  end
end

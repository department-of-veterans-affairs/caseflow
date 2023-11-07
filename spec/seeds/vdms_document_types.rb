describe Seeds::VdmsDocumentTypes do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of users and organizations" do
      expect { subject }.to_not raise_error
    end
  end
end

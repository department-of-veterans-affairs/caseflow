describe VeteranFinder do
  describe "#find" do
    let(:file_number) { "123456789" }
    let(:ssn) { file_number.to_s.reverse } # our fakes do this
    let!(:veteran) { create(:veteran, file_number: file_number) }

    it "fetches based on file_number" do
      expect(subject.find(file_number)).to eq(veteran)
    end

    it "fetches based on SSN" do
      expect(subject.find(ssn)).to eq(veteran)
    end
  end
end

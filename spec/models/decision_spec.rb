describe Decision do

  context "#pdf_location" do
    let(:appeal) { create(:appeal) }
    subject { Decision.new(appeal: appeal).pdf_location }

    it "should fetch file from s3 and return temporary location" do
      expect(Caseflow::Fakes::S3Service).to receive(:fetch_file)
      expect(subject).to eq File.join(Rails.root, "tmp", "pdfs", appeal.external_id + ".pdf")
    end
  end
end

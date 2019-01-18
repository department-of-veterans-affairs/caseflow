describe AsyncableJobs do
  describe "#jobs" do
    let(:veteran) { create(:veteran) }
    let!(:hlr) do
      create(:higher_level_review,
             establishment_submitted_at: 7.days.ago,
             veteran_file_number: veteran.file_number)
    end
    let!(:sc) do
      create(:supplemental_claim,
             establishment_submitted_at: 6.days.ago,
             veteran_file_number: veteran.file_number)
    end

    it "returns an Array of model instances that consume Asyncable concern" do
      expect(subject.jobs).to be_a(Array)
      expect(subject.jobs.length).to eq(2)
      expect(subject.jobs).to include(hlr)
      expect(subject.jobs).to include(sc)
    end

    it "sorts by the submited_at column, descending order" do
      expect(subject.jobs).to eq([hlr, sc])
    end
  end
end

describe AsyncableJobs do
  describe "#jobs" do
    let(:veteran) { create(:veteran) }
    let!(:hlr) do
      create(:higher_level_review,
             establishment_submitted_at: 7.days.ago,
             establishment_attempted_at: 7.days.ago,
             veteran_file_number: veteran.file_number)
    end
    let!(:sc) do
      create(:supplemental_claim,
             establishment_submitted_at: 6.days.ago,
             establishment_attempted_at: 7.days.ago,
             veteran_file_number: veteran.file_number)
    end
    let!(:sc_not_submitted) do
      create(:supplemental_claim,
             establishment_attempted_at: 7.days.ago,
             veteran_file_number: veteran.file_number)
    end
    let!(:sc_not_attempted) do
      create(:supplemental_claim,
             establishment_submitted_at: 2.days.ago,
             veteran_file_number: veteran.file_number)
    end
    let!(:sc_not_attempted_expired) do
      create(:supplemental_claim,
             establishment_submitted_at: 8.days.ago,
             veteran_file_number: veteran.file_number)
    end

    it "returns an Array of model instances that consume Asyncable concern" do
      expect(subject.jobs).to be_a(Array)
      expect(subject.jobs.length).to eq(5)
      expect(subject.jobs).to include(hlr)
      expect(subject.jobs).to include(sc)
      expect(subject.jobs).to include(sc_not_submitted)
      expect(subject.jobs).to include(sc_not_attempted_expired)
      expect(subject.jobs).to include(sc_not_attempted)
    end

    it "sorts by the submited_at column, descending order" do
      expect(subject.jobs).to eq([sc_not_attempted_expired, hlr, sc, sc_not_attempted, sc_not_submitted])
    end
  end

  describe "#models" do
    it "returns list of Asyncable-consuming models" do
      expect(subject.models).to include(HigherLevelReview)
    end

    it "rejects abstract classes" do
      expect(subject.models).to_not include(DecisionReview)
    end
  end
end

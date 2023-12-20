# frozen_string_literal: true

describe AsyncableJobs, :postgres do
  let(:veteran) { create(:veteran) }
  let!(:hlr) do
    create(:higher_level_review,
           establishment_last_submitted_at: 7.days.ago,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "bad problem",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc) do
    create(:supplemental_claim,
           establishment_last_submitted_at: 6.days.ago,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "bad problem",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc_not_submitted) do
    create(:supplemental_claim,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "bad problem",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc_not_attempted) do
    create(:supplemental_claim,
           establishment_last_submitted_at: 2.days.ago,
           veteran_file_number: veteran.file_number)
  end
  let!(:sc_not_attempted_expired) do
    create(:supplemental_claim,
           establishment_last_submitted_at: 8.days.ago,
           veteran_file_number: veteran.file_number)
  end
  let!(:sc_with_error) do
    create(:supplemental_claim,
           veteran_file_number: veteran.file_number,
           establishment_error: "bad problem")
  end

  let!(:sc_canceled) do
    create(:supplemental_claim,
           veteran_file_number: veteran.file_number,
           establishment_error: "bad problem",
           establishment_canceled_at: 2.days.ago)
  end

  describe "#jobs" do
    it "returns an Array of model instances that consume Asyncable concern" do
      expect(subject.jobs).to be_a(Array)
      expect(subject.jobs.length).to eq(6)
      expect(subject.jobs).to include(hlr)
      expect(subject.jobs).to include(sc)
      expect(subject.jobs).to include(sc_not_submitted)
      expect(subject.jobs).to include(sc_not_attempted_expired)
      expect(subject.jobs).to include(sc_not_attempted)
      expect(subject.jobs).to_not include(sc_canceled)
    end

    it "sorts by the submited_at column, descending order" do
      expect(subject.jobs).to eq(
        [sc_not_attempted_expired, hlr, sc, sc_not_attempted, sc_not_submitted, sc_with_error]
      )
    end

    it "includes all unprocessed jobs regardless of whether they have expired" do
      expect(subject.jobs.count(&:expired_without_processing?)).to eq(3)
      expect(subject.jobs.count { |job| !job.expired_without_processing? }).to eq(3)
    end
  end

  describe "#find_by_error" do
    it "searches by regex" do
      expect(subject.find_by_error(/bad problem/).count).to eq(4)
    end

    it "searches by string" do
      expect(subject.find_by_error("bad problem").count).to eq(4)
    end
  end

  describe ".models" do
    it "returns list of Asyncable-consuming models" do
      expect(described_class.models).to include(HigherLevelReview)
    end

    it "rejects abstract classes" do
      expect(described_class.models).to_not include(DecisionReview)
    end
  end

  describe "#total_jobs" do
    context "page_size > 0" do
      subject { described_class.new(page: 2, page_size: 4) }

      it "paginates" do
        expect(subject.jobs.length).to eq(2)
        expect(subject.total_jobs).to eq(6)
        expect(subject.total_pages).to eq(2)
      end
    end

    context "page_size < 0" do
      subject { described_class.new(page_size: -1) }

      it "does not paginate" do
        expect(subject.jobs.length).to eq(6)
        expect(subject.total_jobs).to be_nil
        expect(subject.total_pages).to be_nil
      end
    end
  end
end

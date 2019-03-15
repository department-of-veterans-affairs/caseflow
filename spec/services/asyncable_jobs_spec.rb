# frozen_string_literal: true

describe AsyncableJobs do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

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
  let!(:sc2) do
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

  describe "#jobs" do
    it "returns an Array of model instances that consume Asyncable concern" do
      expect(subject.jobs).to be_a(Array)
      expect(subject.jobs.length).to eq(6)
      expect(subject.jobs).to include(hlr)
      expect(subject.jobs).to include(sc)
      expect(subject.jobs).to include(sc2)
      expect(subject.jobs).to include(sc_not_submitted)
      expect(subject.jobs).to include(sc_not_attempted_expired)
      expect(subject.jobs).to include(sc_not_attempted)
    end

    it "sorts by the submited_at column, descending order" do
      expect(subject.jobs).to eq([sc_not_attempted_expired, hlr, sc, sc2, sc_not_attempted, sc_not_submitted])
    end

    it "includes all unprocessed jobs regardless of whether they have expired" do
      expect(subject.jobs.select(&:expired_without_processing?).count).to eq(4)
      expect(subject.jobs.reject(&:expired_without_processing?).count).to eq(2)
    end
  end

  describe "#summary" do
    it "returns Hash summarizing jobs" do
      expect(subject.summary).to eq(
        "SupplementalClaim" => {
          "8" => { nil => 1 },
          "6" => { "bad problem" => 2 },
          "2" => { nil => 1 },
          "0" => { "bad problem" => 1 }
        },
        "HigherLevelReview" => {
          "7" => { "bad problem" => 1 }
        }
      )
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

  describe "#models" do
    it "returns list of Asyncable-consuming models" do
      expect(subject.models).to include(HigherLevelReview)
    end

    it "rejects abstract classes" do
      expect(subject.models).to_not include(DecisionReview)
    end
  end
end

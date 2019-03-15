# frozen_string_literal: true

describe AsyncableJobsReporter do
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

  subject { AsyncableJobsReporter.new(jobs: AsyncableJobs.new.jobs) }

  describe "#summary" do
    it "returns Hash summarizing jobs" do
      expect(subject.summary).to eq(
        "SupplementalClaim" => {
          "8" => { "none" => 1 },
          "6" => { "bad" => 2 },
          "2" => { "none" => 1 },
          "0" => { "bad" => 1 }
        },
        "HigherLevelReview" => {
          "7" => { "bad" => 1 }
        }
      )
    end
  end

  describe "#summarize" do
    it "writes a report to stdout" do
      msg = <<~HEREDOC
        HigherLevelReview has 1 jobs 7 days old with error bad
        HigherLevelReview has 1 total jobs in queue
        SupplementalClaim has 1 jobs 0 days old with error bad
        SupplementalClaim has 1 jobs 2 days old with error none
        SupplementalClaim has 2 jobs 6 days old with error bad
        SupplementalClaim has 1 jobs 8 days old with error none
        SupplementalClaim has 5 total jobs in queue
      HEREDOC
      expect(subject.summarize).to eq(msg.chomp)
    end
  end
end

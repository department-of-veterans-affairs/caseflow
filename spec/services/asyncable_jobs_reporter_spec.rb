# frozen_string_literal: true

describe AsyncableJobsReporter, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let(:veteran) { create(:veteran) }
  let!(:hlr) do
    create(:higher_level_review,
           establishment_submitted_at: 7.days.ago,
           establishment_last_submitted_at: 7.days.ago,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "bad problem",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc) do
    create(:supplemental_claim,
           establishment_submitted_at: 6.days.ago,
           establishment_last_submitted_at: 6.days.ago,
           establishment_attempted_at: 7.days.ago,
           establishment_error: "problem\nwith multiple\nlines",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc2) do
    create(:supplemental_claim,
           establishment_submitted_at: 6.days.ago,
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
           establishment_submitted_at: 2.days.ago,
           establishment_last_submitted_at: 2.days.ago,
           veteran_file_number: veteran.file_number)
  end
  let!(:sc_not_attempted_expired) do
    create(:supplemental_claim,
           establishment_submitted_at: 8.days.ago,
           establishment_last_submitted_at: 8.days.ago,
           veteran_file_number: veteran.file_number)
  end

  let(:verbose) { true }

  subject { AsyncableJobsReporter.new(jobs: AsyncableJobs.new.jobs, verbose: verbose) }

  describe "#summary" do
    it "returns Hash summarizing jobs" do
      expect(subject.summary).to eq(
        "SupplementalClaim" => {
          "8" => { "none" => 1 },
          "6" => { "bad" => 1, "problem" => 1 },
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
    it "creates a report suitable for puts" do
      msg = <<~HEREDOC
        HigherLevelReview has 1 jobs 7 days old with error bad
        HigherLevelReview has 1 total jobs in queue
        SupplementalClaim has 1 jobs 0 days old with error bad
        SupplementalClaim has 1 jobs 2 days old with error none
        SupplementalClaim has 1 jobs 6 days old with error bad
        SupplementalClaim has 1 jobs 6 days old with error problem
        SupplementalClaim has 1 jobs 8 days old with error none
        SupplementalClaim has 5 total jobs in queue
      HEREDOC
      expect(subject.summarize).to eq(msg.chomp)
    end

    context "when verbose is false" do
      let(:verbose) { false }

      it "is more terse" do
        msg = <<~HEREDOC
          HigherLevelReview has 1 total jobs in queue
          SupplementalClaim has 5 total jobs in queue
        HEREDOC
        expect(subject.summarize).to eq(msg.chomp)
      end
    end
  end

  describe "#as_csv" do
    it "returns a CSV-formatted string" do
      csv = subject.as_csv
      expect(csv)
        .to match(/SupplementalClaim,\d+,#{6.days.ago},#{6.days.ago},#{7.days.ago},bad,#{veteran.participant_id}/)
      expect(CSV.parse(csv).count).to eq(7) # jobs + header
    end
  end
end

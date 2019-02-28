feature "Asyncable Jobs index" do
  before do
    Timecop.freeze(Time.zone.now)
  end

  after do
    Timecop.return
  end

  let(:now) { post_ramp_start_date }
  let(:six_days_ago) { 6.days.ago.strftime(date_format) }

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let(:date_format) { "%a %b %d %T %Y" }
  let(:veteran) { create(:veteran) }
  let(:veteran2) { create(:veteran) }
  let!(:hlr) do
    create(:higher_level_review,
           establishment_last_submitted_at: 7.days.ago,
           establishment_submitted_at: 8.days.ago,
           establishment_attempted_at: 6.days.ago,
           establishment_error: "oops!",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc) do
    create(:supplemental_claim,
           establishment_last_submitted_at: 6.days.ago,
           establishment_attempted_at: 6.days.ago,
           establishment_error: "wrong!",
           veteran_file_number: veteran.file_number)
  end
  let!(:pending_hlr) do
    create(:higher_level_review,
           establishment_last_submitted_at: 2.days.ago,
           veteran_file_number: veteran2.file_number)
  end
  let!(:request_issues_update) do
    create(:request_issues_update, last_submitted_at: 6.days.ago, submitted_at: 6.days.ago)
  end

  describe "index page" do
    it "shows jobs that look potentially stuck" do
      visit "/jobs"

      expect(page).to have_content(veteran.file_number)
      expect(page).to have_content(veteran2.file_number)
    end

    it "shows 'unknown' when no veteran is associated" do
      allow_any_instance_of(RequestIssuesUpdate).to receive(:veteran).and_return(nil)

      visit "/jobs"

      expect(page).to have_content(
        /RequestIssuesUpdate #{six_days_ago} #{six_days_ago} queued unknown Queued/
      )
    end

    it "allows user to restart job" do
      visit "/jobs"

      expect(page).to have_content("oops!")
      expect(page).to have_content("wrong!")
      expect(page).to have_content(hlr.establishment_last_submitted_at.strftime(date_format))

      safe_click "#job-HigherLevelReview-#{hlr.id}"

      expect(page).to have_content("Restarted")
      expect(page).to_not have_content(hlr.establishment_last_submitted_at.strftime(date_format))
      expect(page).to_not have_content("oops!")

      expect(hlr.reload.establishment_last_submitted_at).to be_within(1.second).of Time.zone.now
      expect(hlr.establishment_submitted_at).to be_within(1.second).of 8.days.ago
    end

    context "zero unprocessed jobs" do
      before do
        AsyncableJobs.new.jobs.each(&:processed!)
      end

      it "shows nice message" do
        visit "/jobs"

        expect(page).to have_content("Success! There are no pending jobs.")
      end
    end
  end
end

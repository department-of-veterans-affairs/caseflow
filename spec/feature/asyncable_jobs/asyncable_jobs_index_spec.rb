# frozen_string_literal: true

feature "Asyncable Jobs index", :postgres do
  before do
    Timecop.freeze(Time.zone.now)
  end

  after do
    Timecop.return
  end

  let(:now) { post_ramp_start_date }
  let(:six_days_ago) { 6.days.ago.unix_format }

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let(:veteran) { create(:veteran) }
  let(:veteran2) { create(:veteran) }
  let!(:hlr_intake) { create(:intake, detail: hlr) }
  let!(:hlr) do
    create(:higher_level_review,
           establishment_last_submitted_at: 7.days.ago,
           establishment_submitted_at: 8.days.ago,
           establishment_attempted_at: 6.days.ago,
           establishment_error: "oops!",
           veteran_file_number: veteran.file_number)
  end
  let!(:sc_intake) { create(:intake, detail: sc) }
  let!(:sc) do
    create(:supplemental_claim,
           establishment_last_submitted_at: 6.days.ago,
           establishment_attempted_at: 6.days.ago + 2.hours,
           establishment_error: "wrong!",
           veteran_file_number: veteran.file_number)
  end
  let!(:pending_hlr_intake) { create(:intake, detail: pending_hlr) }
  let!(:pending_hlr) do
    create(:higher_level_review,
           establishment_last_submitted_at: 2.days.ago,
           establishment_error: "SomeError: this is a really long exception message\nover multiple lines",
           veteran_file_number: veteran2.file_number)
  end
  let!(:request_issues_update) do
    create(:request_issues_update, last_submitted_at: 6.days.ago, submitted_at: 6.days.ago)
  end
  let!(:request_issues) do
    50.times do
      create(:request_issue, decision_sync_last_submitted_at: 1.day.ago) # fewer days to sort others first
    end
  end

  describe "individual job page" do
    it "shows job details" do
      visit "/asyncable_jobs/HigherLevelReview/jobs/#{hlr.id}"

      expect(page).to have_content(hlr.establishment_error)

      click_link hlr_intake.user.css_id

      expect(page).to have_current_path(manager_path(user_css_id: hlr_intake.user.css_id))
    end

    it "restart individual job" do
      visit "/asyncable_jobs/HigherLevelReview/jobs/#{hlr.id}"

      expect(page).to_not have_content("Attempted n/a")
      expect(page).to have_button("Restart")

      safe_click "#job-HigherLevelReview-#{hlr.id}"

      expect(page).to have_button("Restarted", disabled: true)
      expect(page).to have_content("Attempted n/a")
    end

    it "displays and adds notes" do
      hlr.job_notes << JobNote.new(note: "hello world", user: hlr_intake.user)

      visit "/asyncable_jobs/HigherLevelReview/jobs/#{hlr.id}"

      expect(page).to have_content("hello world")

      fill_in "Add Note", with: "another note\nwith\n## markdown header!"
      click_button "Add Note"

      expect(page).to have_content("another note\nwith\nmarkdown header!")
      expect(hlr.reload.job_notes.count).to eq(2)
      expect(hlr_intake.user.messages.last.detail).to eq(hlr.job_notes.last)
    end
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
        /RequestIssuesUpdate #{request_issues_update.id} #{six_days_ago} queued unknown Queued/
      )
    end

    it "allows user to restart job" do
      visit "/jobs"

      expect(page).to have_content("oops!")
      expect(page).to have_content("wrong!")
      expect(page).to have_content(hlr.establishment_submitted_at.unix_format)
      expect(page).to have_content(hlr.establishment_attempted_at.unix_format)
      expect(page).to_not have_content("Restarted")

      hlr_submitted = hlr.establishment_submitted_at.unix_format
      hlr_attempted = hlr.establishment_attempted_at.unix_format

      expect(page).to have_content("HigherLevelReview #{hlr.id} #{hlr_submitted} #{hlr_attempted}")

      safe_click "#job-HigherLevelReview-#{hlr.id}"

      expect(page).to have_content("Restarted")
      expect(page).to have_content("HigherLevelReview #{hlr.id} #{hlr_submitted} queued")
      expect(page).to_not have_content("oops!")

      expect(hlr.reload.establishment_last_submitted_at).to be_within(1.second).of Time.zone.now
      expect(hlr.establishment_submitted_at).to be_within(1.second).of 8.days.ago
    end

    it "allows user to page through jobs" do
      visit "/jobs"

      expect(page).to have_content("Viewing 1-50 of 54 total")

      page.execute_script("document.querySelector('[name=page-button-1]').click()")

      expect(current_url).to match(/\?page=2/)
      expect(page).to have_content("Viewing 51-54 of 54 total")
    end

    it "links to individual jobs" do
      visit "/jobs"

      click_link "HigherLevelReview #{hlr.id}"

      expect(current_path).to eq("/asyncable_jobs/HigherLevelReview/jobs/#{hlr.id}")
    end

    it "filters out long error messages" do
      visit "/jobs"

      expect(page).to_not have_content("this is a really long exception message")
      expect(page).to_not have_content("over multiple lines")
    end

    it "links to Intake user" do
      visit "/jobs"

      click_link hlr_intake.user.css_id

      expect(page).to have_current_path(manager_path(user_css_id: hlr_intake.user.css_id))
    end

    it "links to CSV export" do
      visit "/jobs"

      expect(page).to have_content "Download as CSV"
    end

    context "zero unprocessed jobs" do
      before do
        AsyncableJobs.new(page_size: 100).jobs.each(&:clear_error!).each(&:processed!)
      end

      it "shows nice message" do
        visit "/jobs"

        expect(page).to have_content("There are no pending jobs.")
      end
    end
  end
end

# frozen_string_literal: true

feature "Jobs Page Search", :postgres do
  let(:intake_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end
  let(:veteran_file_one) { "123456789" }
  let(:veteran_file_two) { "963360019" }
  let(:no_jobs_veteran_file_number) { "no_jobs_veteran_file_number" }
  let(:hlr) do
    create(
      :higher_level_review,
      :requires_processing,
      intake: create(:intake, user: intake_user),
      veteran_file_number: veteran_file_one
    )
  end
  let(:hlr2) do
    create(
      :higher_level_review,
      :requires_processing,
      intake: create(:intake, user: intake_user),
      veteran_file_number: veteran_file_two
    )
  end
  let(:dd) { create(:decision_document) }

  context "for jobs using Veteran file number" do
    context "when valid Veteran file number is associated with a job" do
      before do
        visit "/jobs"
        find(:css, "cf-search-input-with-close").set(veteran_file_one)
        click_button(class: "cf-submit usa-button")
      end

      it "page displays jobs results for Veteran file number with jobs" do
        expect(page).to have_content(veteran_file_one, count: 2) # File number once in search and once in table
      end
    end

    context "when Veteran file number is not associated with a job" do
      before do
        visit "/jobs"
        find(:css, "cf-search-input-with-close").set(no_jobs_veteran_file_number)
        click_button(class: "cf-submit usa-button")
      end

      it "page displays message that there are no pending jobs for Veteran file" do
        expect(page).to have_content("There are no pending job for Veteran file number #{no_jobs_veteran_file_number}.")
      end
    end
  end

  context "not searching by Veteran file number" do
    it " should show all jobs" do
      expect(page).to have_content(veteran_file_one)
      expect(page).to have_content(veteran_file_two)
    end
  end
end

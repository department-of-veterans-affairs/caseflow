# frozen_string_literal: true

feature "Jobs Page Search", :postgres do
  let(:intake_user) { create(:user) }

  let(:veteran_file_number_one) { "123456789" }
  let(:veteran_file_number_two) { "963360019" }
  let(:no_jobs_veteran_file_number) { "no_jobs_veteran_file_number" }
  let(:hlr) { create(:higher_level_review, :requires_processing, intake: create(:intake, user: intake_user), veteran_file_number: veteran_file_number_one)}
  let(:hlr2) { create(:higher_level_review, :requires_processing, intake: create(:intake, user: intake_user), veteran_file_number: veteran_file_number_two)}

  before do
    User.authenticate!(user: intake_user)
  end

  context "search for jobs using Veteran file number" do
    context "when valid Veteran file number is associated with a job" do
      before do
        visit "/jobs"
        fill_in "searchBar", with: veteran_file_number
        click_on "Search"
      end

      it "page displays jobs results for Veteran file number with jobs" do
      end
    end

    context "when Veteran file number is not associated with a job" do
      before do
        visit "/jobs"
        fill_in "searchBar", with: no_jobs_veteran_file_number
        click_on "Search"
      end

      it "page displays message that there is no pending result " do
        # expect(page) to contain "There are no pending jobs for Veteran file number "
      end
    end
  end

  context "not searching by Veteran file number should show all jobs" do
      # expect(page) to contain 2 jobs
  end
end

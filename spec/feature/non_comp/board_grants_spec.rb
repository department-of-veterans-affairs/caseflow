require "rails_helper"

feature "NonComp Board Grant Task Page" do
  before do
    FeatureToggle.enable!(:decision_reviews)
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  def submit_form
    find("label[for=isEffectuated]").click
    click_on "Complete"
  end

  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:user) { create(:default_user) }
  let(:veteran) { create(:veteran) }
  let(:prior_date) { Time.zone.now - 2.days }

  let(:appeal) do
    create(:appeal,
           veteran: veteran)
  end

  let(:dispositions) { %w[allowed allowed denied] }

  let!(:request_issues) do
    3.times do |index|
      request_issue = create(:request_issue,
                             :nonrating,
                             veteran_participant_id: veteran.participant_id,
                             review_request: appeal)

      request_issue.create_decision_issue_from_params(
        disposition: dispositions[index],
        description: "disposition #{index}",
        decision_date: prior_date
      )
    end
  end

  let!(:in_progress_task) do
    create(:board_grant_effectuation_task, :in_progress, appeal: appeal, assigned_to: non_comp_org)
  end

  let(:business_line_url) { "decision_reviews/nco" }
  let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }

  before do
    User.stub = user
    OrganizationsUser.add_user_to_organization(user, non_comp_org)
  end

  scenario "cancel returns back to business line" do
    visit dispositions_url

    click_on "Cancel"
    expect(page).to have_current_path("/#{business_line_url}")
  end

  scenario "completes task" do
    visit dispositions_url

    expect(page).to have_button("Complete", disabled: true)
    expect(page).to have_content("Non-Comp Org")
    expect(page).to have_content("Decision")
    expect(page).to have_content(veteran.name)
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.appeal)

    # expect to have the two granted decision issues
    expect(page).to have_content("GRANTED", count: 2)
    expect(page).to have_content("disposition 0")
    expect(page).to have_content("disposition 1")

    submit_form
    # should have success message
    expect(page).to have_content("Decision Completed")
    # should redirect to business line's completed tab
    expect(page.current_path).to eq "/#{business_line_url}"
    expect(page).to have_content(appeal.claimants.first.participant_id)
    in_progress_task.reload
    expect(in_progress_task.status).to eq("completed")
    expect(in_progress_task.completed_at).to eq(Time.zone.now)

    # click on completed task and verify that it is not editable
    click_link veteran.name
    expect(page).to have_content("Board Grants")
    expect(page).to have_current_path("/#{dispositions_url}")
    expect(page).not_to have_css("[id='isEffectuated'][disabled]")
    expect(page).not_to have_button("Complete")
  end

  context "when there is an error saving" do
    scenario "Shows an error when something goes wrong" do
      visit dispositions_url

      expect_any_instance_of(BoardGrantEffectuationTask).to receive(:complete_with_payload!).and_throw("Error!")
      submit_form

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/#{dispositions_url}")
    end
  end
end

# frozen_string_literal: true

feature "NonComp Board Grant Task Page", :postgres do
  before do
    User.stub = user
    nca_org.add_user(user)
    Timecop.freeze(post_ama_start_date)
    FeatureToggle.enable!(:decision_review_queue_ssn_column)
  end

  after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }

  def submit_form
    find("label[for=isEffectuated]").click
    click_on "Complete"
  end

  let!(:nca_org) { create(:business_line, name: "national cemetary association", url: "nca") }
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
                             decision_review: appeal,
                             benefit_type: nca_org.url)

      request_issue.create_decision_issue_from_params(
        disposition: dispositions[index],
        description: "disposition nca #{index}",
        decision_date: prior_date
      )
    end
  end

  let!(:in_progress_task) do
    create(:board_grant_effectuation_task, :in_progress, appeal: appeal, assigned_to: nca_org)
  end

  let(:business_line_url) { "decision_reviews/nca" }
  let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }
  let(:vet_id_column_value) { appeal.veteran.ssn }

  scenario "cancel returns back to business line" do
    visit dispositions_url

    click_on "Cancel"
    expect(page).to have_current_path("/#{business_line_url}", ignore_query: true)
  end

  scenario "completes task" do
    visit dispositions_url

    expect(page).to have_button("Complete", disabled: true)
    expect(page).to have_content("national cemetary association")
    expect(page).to have_content("Decision")
    expect(page).to have_content(veteran.name)
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.appeal)

    # expect to have the two granted decision issues
    expect(page).to have_content("GRANTED", count: 2)
    expect(page).to have_content("disposition nca 0")
    expect(page).to have_content("disposition nca 1")

    submit_form
    # should have success message
    expect(page).to have_content("Decision Completed")
    # should redirect to business line's completed tab
    expect(page.current_path).to eq "/#{business_line_url}"
    expect(page).to have_content(vet_id_column_value)
    in_progress_task.reload
    expect(in_progress_task.status).to eq("completed")
    expect(in_progress_task.closed_at).to eq(Time.zone.now)

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

  context "appeal with issues for multiple organizations" do
    before do
      vha_org.add_user(user)
    end

    let!(:vha_org) { VhaBusinessLine.singleton }

    let!(:vha_request_issues) do
      3.times do |index|
        request_issue = create(:request_issue,
                               :nonrating,
                               veteran_participant_id: veteran.participant_id,
                               decision_review: appeal,
                               benefit_type: vha_org.url)

        request_issue.create_decision_issue_from_params(
          disposition: dispositions[index],
          description: "disposition vha #{index}",
          decision_date: prior_date
        )
      end
    end

    let!(:in_progress_vha_task) do
      create(:board_grant_effectuation_task, :in_progress, appeal: appeal, assigned_to: vha_org)
    end

    let(:vha_dispositions_url) { "decision_reviews/vha/tasks/#{in_progress_vha_task.id}" }

    scenario "displays board grants page with correct dispositions" do
      # only include dispositions from request issues matching the benefit type
      # when this test executes, the nca business line with request issues already exists

      visit vha_dispositions_url
      expect(page).to have_content("Veterans Health Administration")
      expect(page).to have_content("Decision")
      expect(page).to have_content(veteran.name)
      expect(page).to have_content(Constants.INTAKE_FORM_NAMES.appeal)
      expect(page).to have_content(prior_date.strftime("%m/%d/%Y"))

      # expect to have the two granted decision issues
      expect(page).to have_content("GRANTED", count: 2)
      expect(page).to have_content("disposition vha 0")
      expect(page).to have_content("disposition vha 1")

      # expect decision issues associated with nca benefit type to not exist
      expect(page).to_not have_content("disposition nca 0")
      expect(page).to_not have_content("disposition nca 1")
    end
  end
end

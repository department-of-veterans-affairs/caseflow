# frozen_string_literal: true

feature "NonComp Record Request Page", :postgres do
  before do
    User.stub = user
    non_comp_org.add_user(user)
    Timecop.freeze(post_ama_start_date)
    FeatureToggle.enable!(:decision_review_queue_ssn_column)
  end

  after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }

  def submit_form
    find("label[for=isSent]").click
    click_on "Confirm"
  end

  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:user) { create(:default_user) }
  let(:veteran) { create(:veteran) }
  let(:prior_date) { Time.zone.now - 2.days }

  let(:appeal) do
    create(:appeal,
           veteran: veteran)
  end

  let!(:in_progress_task) do
    task = create(:veteran_record_request_task, :in_progress, appeal: appeal, assigned_to: non_comp_org)
    create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)
    task
  end

  let(:business_line_url) { "decision_reviews/nco" }
  let(:task_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }
  let(:vet_id_column_value) { appeal.veteran.ssn }

  scenario "cancel returns back to business line" do
    visit task_url

    click_on "Cancel"
    expect(page).to have_current_path("/#{business_line_url}", ignore_query: true)
  end

  scenario "completes task" do
    visit task_url

    expect(page).to have_button("Confirm", disabled: true)
    expect(page).to have_content("Non-Comp Org")
    expect(page).to have_content(veteran.name.to_s)
    expect(page).to have_content(Constants.INTAKE_FORM_NAMES.appeal)

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
    expect(page).to have_content("Request to send Veteran record to the Board")
    expect(page).to have_content("Case Review and Evaluation Branch")
    expect(page).to have_current_path("/#{task_url}")
    expect(page).not_to have_css("[id='isSent'][disabled]")
    expect(page).not_to have_button("Confirm")
  end

  context "when there is an error saving" do
    scenario "Shows an error when something goes wrong" do
      visit task_url

      expect_any_instance_of(VeteranRecordRequest).to receive(:complete_with_payload!).and_throw("Error!")
      submit_form

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/#{task_url}")
    end
  end
end

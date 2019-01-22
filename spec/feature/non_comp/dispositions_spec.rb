require "rails_helper"

feature "NonComp Dispositions Task Page" do
  before do
    FeatureToggle.enable!(:decision_reviews)
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  def fill_in_disposition(num, disposition, description = nil)
    if description
      fill_in "description-issue-#{num}", with: description
    end

    fill_in "disposition-issue-#{num}", with: disposition
    find("#disposition-issue-#{num}").send_keys :enter
  end

  def find_disabled_disposition(num, disposition, description = nil)
    expect(page).to have_field(type: "textarea", with: description, disabled: true)

    within(".dropdown-disposition-issue-#{num}") do
      expect(find("span[class='Select-value-label']", text: disposition)).to_not be_nil
    end
    expect(page).to have_css("[id='disposition-issue-#{num}'][aria-readonly='true']")
  end

  context "with an existing organization" do
    let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }

    let(:user) { create(:default_user) }

    let(:veteran) { create(:veteran) }

    let(:epe) { create(:end_product_establishment, veteran_file_number: veteran.file_number) }

    let(:hlr) do
      create(
        :higher_level_review,
        end_product_establishments: [epe],
        veteran_file_number: veteran.file_number
      )
    end

    let!(:request_issues) do
      3.times do
        create(:request_issue,
               :nonrating,
               end_product_establishment: epe,
               veteran_participant_id: veteran.participant_id,
               review_request: hlr)
      end
    end

    let!(:in_progress_task) do
      create(:higher_level_review_task, :in_progress, appeal: hlr, assigned_to: non_comp_org)
    end

    let(:business_line_url) { "decision_reviews/nco" }
    let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }
    before do
      User.stub = user
      OrganizationsUser.add_user_to_organization(user, non_comp_org)
    end

    scenario "displays dispositions page" do
      visit dispositions_url

      expect(page).to have_content("Non-Comp Org")
      expect(page).to have_content("Decision")
      expect(page).to have_content(veteran.name)
      expect(page).to have_content(
        "Prior decision date: #{hlr.request_issues[0].decision_date.strftime('%m/%d/%Y')}"
      )
      expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    end

    scenario "cancel returns back to business line page" do
      visit dispositions_url

      click_on "Cancel"
      expect(page).to have_current_path("/#{business_line_url}")
    end

    scenario "saves decision issues" do
      visit dispositions_url

      expect(page).to have_button("Complete", disabled: true)

      # set description & disposition for each request issue
      fill_in_disposition(0, "Granted")
      fill_in_disposition(1, "Granted", "test description")
      fill_in_disposition(2, "Denied", "denied")

      # save
      expect(page).to have_button("Complete", disabled: false)
      click_on "Complete"

      # should have success message
      expect(page).to have_content("Decision Completed")
      # should redirect to business line's completed tab
      expect(page.current_path).to eq "/#{business_line_url}"
      expect(page).to have_content(veteran.participant_id)

      # verify database updated
      hlr.decision_issues.reload
      expect(hlr.decision_issues.length).to eq(3)
      expect(hlr.decision_issues.find_by(disposition: "Granted", description: nil)).to_not be_nil
      expect(hlr.decision_issues.find_by(disposition: "Granted", description: "test description")).to_not be_nil
      expect(hlr.decision_issues.find_by(disposition: "Denied", description: "denied")).to_not be_nil

      # verify that going to the completed task does not allow edits
      click_link veteran.name
      expect(page).to have_content("Review each issue and assign the appropriate dispositions")
      expect(page).to have_current_path("/#{dispositions_url}")
      expect(page).not_to have_button("Complete")

      find_disabled_disposition(0, "Granted")
      find_disabled_disposition(1, "Granted", "test description")
      find_disabled_disposition(2, "Denied", "denied")
    end

    context "when there is an error saving" do
      scenario "Shows an error when something goes wrong" do
        visit dispositions_url

        expect_any_instance_of(DecisionReviewTask).to receive(:complete_with_payload!).and_throw("Error!")

        fill_in_disposition(0, "Granted")
        fill_in_disposition(1, "Granted", "test description")
        fill_in_disposition(2, "Denied", "denied")

        click_on "Complete"
        expect(page).to have_content("Something went wrong")
        expect(page).to have_current_path("/#{dispositions_url}")
      end
    end

    context "with user enabled for intake" do
      before do
        FeatureToggle.enable!(:intake)

        # allow user to have access to intake
        user.update(roles: user.roles << "Mail Intake")
        Functions.grant!("Mail Intake", users: [user.css_id])
      end

      after do
        FeatureToggle.disable!(:intake)
      end

      scenario "goes back to intake" do
        visit dispositions_url
        click_on "Edit Issues"

        expect(page).to have_current_path(hlr.reload.caseflow_only_edit_issues_url)
      end
    end
  end
end

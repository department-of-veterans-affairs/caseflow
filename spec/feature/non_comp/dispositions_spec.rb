require "rails_helper"

feature "NonComp Dispositions Page" do
  before do
    FeatureToggle.enable!(:decision_reviews)
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
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

    let(:request_issues) do
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

    let!(:completed_task) do
      create(:higher_level_review_task, :completed, appeal: hlr, assigned_to: non_comp_org)
    end

    let(:dispositions_url) { "decision_reviews/nco/tasks/#{in_progress_task.id}" }

    before do
      User.stub = user
      OrganizationsUser.add_user_to_organization(user, non_comp_org)
    end

    scenario "displays dispositions page" do
      visit dispositions_url

      expect(page).to have_content("Non-Comp Org")
      expect(page).to have_content("Decision")
      expect(page).to have_content(veteran.name)
      expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
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

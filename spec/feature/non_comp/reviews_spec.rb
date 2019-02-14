feature "NonComp Reviews Queue" do
  before do
    FeatureToggle.enable!(:decision_reviews)
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  context "with an existing organization" do
    let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
    let(:user) { create(:default_user) }

    let(:veteran_a) { create(:veteran, first_name: "Aaa") }
    let(:veteran_b) { create(:veteran, first_name: "Bbb") }
    let(:veteran_c) { create(:veteran, first_name: "Ccc") }
    let(:hlr_a) { create(:higher_level_review, veteran_file_number: veteran_a.file_number) }
    let(:hlr_b) { create(:higher_level_review, veteran_file_number: veteran_b.file_number) }
    let(:appeal) { create(:appeal, veteran: veteran_c) }

    let(:today) { Time.zone.now }
    let(:last_week) { Time.zone.now - 7.days }

    let!(:in_progress_tasks) do
      [
        create(:higher_level_review_task,
               :in_progress,
               appeal: hlr_a,
               assigned_to: non_comp_org,
               assigned_at: last_week),
        create(:higher_level_review_task,
               :in_progress,
               appeal: hlr_b,
               assigned_to: non_comp_org,
               assigned_at: today),
        create(:board_grant_effectuation_task,
               :in_progress,
               appeal: appeal,
               assigned_to: non_comp_org,
               assigned_at: 1.day.ago)
      ]
    end

    let!(:completed_tasks) do
      [
        create(:higher_level_review_task,
               :completed,
               appeal: hlr_a,
               assigned_to: non_comp_org,
               closed_at: last_week),
        create(:higher_level_review_task,
               :completed,
               appeal: hlr_b,
               assigned_to: non_comp_org,
               closed_at: today)
      ]
    end

    before do
      User.stub = user
      OrganizationsUser.add_user_to_organization(user, non_comp_org)
    end

    scenario "displays tasks page" do
      visit "decision_reviews/nco"
      expect(page).to have_content("Non-Comp Org")
      expect(page).to have_content("In progress tasks")
      expect(page).to have_content("Completed tasks")

      # default is the in progress page
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Higher-Level Review", count: 2)
      expect(page).to have_content("Board Grant")
      expect(page).to have_content(veteran_a.name)
      expect(page).to have_content(veteran_b.name)
      expect(page).to have_content(veteran_c.name)
      expect(page).to have_content(veteran_a.participant_id)
      expect(page).to have_content(veteran_b.participant_id)
      expect(page).to have_content(veteran_c.participant_id)

      # ordered by assigned_at descending

      expect(page).to have_content(
        /#{veteran_b.name} .+? #{veteran_c.name} .+? #{veteran_a.name}/
      )

      click_on "Completed tasks"
      expect(page).to have_content("Higher-Level Review", count: 2)
      expect(page).to have_content("Date Completed")

      # ordered by closed_at descending
      expect(page).to have_content(
        /#{veteran_b.name} 5\d+ 0 [\d\/]+ Higher-Level Review #{veteran_a.name} 5\d+ 0 [\d\/]+/
      )
    end

    context "with user enabled for intake" do
      before do
        FeatureToggle.enable!(:intake)
      end

      after do
        FeatureToggle.disable!(:intake)
      end

      scenario "goes back to intake" do
        # allow user to have access to intake
        user.update(roles: user.roles << "Mail Intake")
        Functions.grant!("Mail Intake", users: [user.css_id])

        visit "decision_reviews/nco"
        click_on "Intake new form"
        expect(page).to have_current_path("/intake")
      end
    end
  end
end

require "rails_helper"

feature "NonComp Reviews Queue" do
  before do
    FeatureToggle.enable!(:decision_reviews)

    # freeze the local time so that our date math is predictable.
    Timecop.freeze(Time.new(2019, 1, 7, 20, 55, 0).in_time_zone)
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  context "with an existing organization" do
    let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
    let(:user) { create(:default_user) }

    let(:veteran) { create(:veteran) }
    let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }

    let(:today) { Time.zone.now }
    let(:last_week) { Time.zone.now - 7.days }

    let!(:in_progress_tasks) do
      [
        create(:higher_level_review_task, :in_progress, appeal: hlr, assigned_to: non_comp_org, assigned_at: last_week),
        create(:higher_level_review_task, :in_progress, appeal: hlr, assigned_to: non_comp_org, assigned_at: today)
      ]
    end

    let!(:completed_tasks) do
      [
        create(:higher_level_review_task, :completed, appeal: hlr, assigned_to: non_comp_org, completed_at: last_week),
        create(:higher_level_review_task, :completed, appeal: hlr, assigned_to: non_comp_org, completed_at: today)
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
      expect(page).to have_content("Bob Smith", count: 2)
      expect(page).to have_content(veteran.participant_id, count: 2)

      # ordered by assigned_at descending
      expect(page).to have_content(
        /#{veteran.name} 5\d+ 0 0 Higher-Level Review #{veteran.name} 5\d+ 0 7/
      )

      click_on "Completed tasks"
      expect(page).to have_content("Higher-Level Review", count: 2)
      expect(page).to have_content("Date Sent")

      # ordered by completed_at descending
      expect(page).to have_content(
        /#{today.strftime("%D")} Higher-Level Review #{veteran.name} 5\d+ 0 #{last_week.strftime("%D")}/
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

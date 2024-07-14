# frozen_string_literal: true

RSpec.feature "Test Docket Case Seeds" do
  unless Rake::Task.task_defined?("assets:precompile")
    Rails.application.load_tasks
  end
  let!(:current_user) do
    user = create(:user, css_id: "BVALNICK")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the test seeds page" do
      login
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the test seeds page" do
      login
    end

    scenario "visits page and creates AMA AOD Hearing Seeds" do
      login
      fill_in "seed-count-ama-aod-hearing-seeds", with: 2
      fill_in "days-ago-ama-aod-hearing-seeds", with: 10
      fill_in "css-id-ama-aod-hearing-seeds", with: current_user.css_id + "10"

      click_button "btn-ama-aod-hearing-seeds"

      expect(find("#preview-table")).to have_content("ama-aod-hearing-seeds")
      expect(find("#preview-table")).to have_content("2 Cases")
      expect(find("#preview-table")).to have_content("10 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}10")

      click_button "button-Create-1-test-cases"

      # TO BE REPLACED WITH CAPYBARA WAIT METHOD
      sleep 5
      expect(Appeal.count).to eq(2)
      hearing_case = Appeal.last
      expect(hearing_case.aod_based_on_age).to be_truthy
      expect(hearing_case.docket_type).to eq("hearing")
      expect(hearing_case.hearings.first.disposition).to eq("held")
      expect(hearing_case.hearings.first.judge.css_id).to eq("#{current_user.css_id}10")
      expect(hearing_case.receipt_date).to eq(Date.parse(10.days.ago.to_s))
      expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
        .to eq(Date.parse(10.days.ago.to_s))
    end

    scenario "visits page and creates AMA Non-AOD Hearing Seeds" do
      login
      fill_in "seed-count-ama-non-aod-hearing-seeds", with: 2
      fill_in "days-ago-ama-non-aod-hearing-seeds", with: 10
      fill_in "css-id-ama-non-aod-hearing-seeds", with: current_user.css_id + "10"

      click_button "btn-ama-non-aod-hearing-seeds"

      expect(find("#preview-table")).to have_content("ama-non-aod-hearing-seeds")
      expect(find("#preview-table")).to have_content("2 Cases")
      expect(find("#preview-table")).to have_content("10 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}10")

      click_button "button-Create-1-test-cases"

      # TO BE REPLACED WITH CAPYBARA WAIT METHOD
      sleep 5
      expect(Appeal.count).to eq(2)
      hearing_case = Appeal.last
      expect(hearing_case.aod_based_on_age).to be_falsey
      expect(hearing_case.docket_type).to eq("hearing")
      expect(hearing_case.hearings.first.disposition).to eq("held")
      expect(hearing_case.hearings.first.judge.css_id).to eq("#{current_user.css_id}10")
      expect(hearing_case.receipt_date).to eq(Date.parse(10.days.ago.to_s))
      expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
        .to eq(Date.parse(10.days.ago.to_s))
    end

    scenario "visits page and creates Legacy Case Seeds" do
      login
      fill_in "seed-count-legacy-case-seeds", with: 2
      fill_in "days-ago-legacy-case-seeds", with: 10
      fill_in "css-id-legacy-case-seeds", with: current_user.css_id + "10"

      click_button "btn-legacy-case-seeds"

      expect(find("#preview-table")).to have_content("legacy-case-seeds")
      expect(find("#preview-table")).to have_content("2 Cases")
      expect(find("#preview-table")).to have_content("10 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}10")

      click_button "button-Create-1-test-cases"

      # TO BE REPLACED WITH CAPYBARA WAIT METHOD
      sleep 5
      expect(LegacyAppeal.count).to eq(2)
    end

    scenario "visits page and creates Direct Review Hearing Seeds" do
      login
      fill_in "seed-count-ama-direct-review-seeds", with: 2
      fill_in "days-ago-ama-direct-review-seeds", with: 10
      fill_in "css-id-ama-direct-review-seeds", with: current_user.css_id + "10"

      click_button "btn-ama-direct-review-seeds"
      expect(find("#preview-table")).to have_content("ama-direct-review-seeds")
      expect(find("#preview-table")).to have_content("2 Cases")
      expect(find("#preview-table")).to have_content("10 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}10")

      click_button "button-Create-1-test-cases"

      # TO BE REPLACED WITH CAPYBARA WAIT METHOD
      sleep 5
      expect(Appeal.count).to eq(2)
      direct_review = Appeal.last
      expect(direct_review.docket_type).to eq("direct_review")
      expect(direct_review.receipt_date).to eq(Date.parse(10.days.ago.to_s))
      expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
        .to eq(Date.parse(10.days.ago.to_s))
    end

    scenario "visits page and creates multiple of each seeds type" do
      login
      fill_in "seed-count-ama-aod-hearing-seeds", with: 2
      fill_in "days-ago-ama-aod-hearing-seeds", with: 10
      fill_in "css-id-ama-aod-hearing-seeds", with: current_user.css_id + "10"
      fill_in "seed-count-ama-non-aod-hearing-seeds", with: 3
      fill_in "days-ago-ama-non-aod-hearing-seeds", with: 11
      fill_in "css-id-ama-non-aod-hearing-seeds", with: current_user.css_id + "11"
      fill_in "seed-count-legacy-case-seeds", with: 4
      fill_in "days-ago-legacy-case-seeds", with: 12
      fill_in "css-id-legacy-case-seeds", with: current_user.css_id + "12"
      fill_in "seed-count-ama-direct-review-seeds", with: 5
      fill_in "days-ago-ama-direct-review-seeds", with: 13
      fill_in "css-id-ama-direct-review-seeds", with: current_user.css_id + "13"

      click_button "btn-ama-aod-hearing-seeds"
      click_button "btn-ama-non-aod-hearing-seeds"
      click_button "btn-legacy-case-seeds"
      click_button "btn-ama-direct-review-seeds"

      expect(find("#preview-table")).to have_content("ama-aod-hearing-seeds")
      expect(find("#preview-table")).to have_content("2 Cases")
      expect(find("#preview-table")).to have_content("10 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}10")
      expect(find("#preview-table")).to have_content("ama-non-aod-hearing-seeds")
      expect(find("#preview-table")).to have_content("3 Cases")
      expect(find("#preview-table")).to have_content("11 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}11")
      expect(find("#preview-table")).to have_content("legacy-case-seeds")
      expect(find("#preview-table")).to have_content("4 Cases")
      expect(find("#preview-table")).to have_content("12 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}12")
      expect(find("#preview-table")).to have_content("ama-direct-review-seeds")
      expect(find("#preview-table")).to have_content("5 Cases")
      expect(find("#preview-table")).to have_content("13 Days Ago")
      expect(find("#preview-table")).to have_content("#{current_user.css_id}13")

      click_button "button-Create-4-test-cases"

      # TO BE REPLACED WITH CAPYBARA WAIT METHOD
      sleep 10
      expect(Appeal.count).to eq(10)
      expect(Appeal.where(docket_type: "hearing", aod_based_on_age: true).count).to eq(2)
      expect(Appeal.where(docket_type: "hearing", aod_based_on_age: nil).count).to eq(3)
      expect(LegacyAppeal.count).to eq(4)
      expect(Appeal.where(docket_type: "direct_review").count).to eq(5)
    end
  end

  def login
    visit "test/seeds"
    visit "test/seeds"
  end
end

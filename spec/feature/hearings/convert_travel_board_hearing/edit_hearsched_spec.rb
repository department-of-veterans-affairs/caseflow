# frozen_string_literal: true

RSpec.feature "Convert travel board appeal for 'Edit HearSched' (Hearing Coordinator)" do
  let!(:current_user) { User.authenticate!(roles: ["Edit HearSched"]) }
  let!(:vacols_case) do
    create(
      :case,
      bfhr: "2" # Travel Board
    )
  end
  let!(:legacy_appeal) do
    create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: vacols_case
    )
  end

  let!(:dispatched_vacols_case) do
    create(
      :case,
      bfhr: "2" # Travel Board
    )
  end
  let!(:dispatched_legacy_appeal) do
    create(
      :legacy_appeal,
      :with_veteran,
      status: "Complete",
      vacols_case: dispatched_vacols_case
    )
  end

  before do
    HearingsManagement.singleton.add_user(current_user)
  end

  context "with FeatureToggle enabled" do
    before do
      FeatureToggle.enable!(:convert_travel_board_to_video_or_virtual)
    end

    after do
      FeatureToggle.disable!(:convert_travel_board_to_video_or_virtual)
    end

    scenario "it does not create a ChangeHearingRequestTypeTask for dispatched appeals" do
      visit "queue/appeals/#{dispatched_legacy_appeal.vacols_id}"

      expect(page).not_to have_content(ScheduleHearingTask.label)
      expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)
      expect(ChangeHearingRequestTypeTask.count).to eq(0)
    end

    scenario "it creates a ChangeHearingRequestTypeTask" do
      visit "queue/appeals/#{legacy_appeal.vacols_id}"

      expect(page).to have_content(ScheduleHearingTask.label)
      expect(page).to have_content(ChangeHearingRequestTypeTask.label)
      click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)
      expect(ChangeHearingRequestTypeTask.count).to eq(1)
      expect(ChangeHearingRequestTypeTask.first.appeal.vacols_id).to eq(legacy_appeal.vacols_id)
    end

    scenario "user can change a hearing from travel to virtual" do
      visit "queue/appeals/#{legacy_appeal.vacols_id}"

      step "select change hearing request type action" do
        click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)
      end

      step "ensure page has veteran and representative info" do
        expect(page).to have_content(legacy_appeal.veteran_full_name)
        expect(page).to have_content(legacy_appeal.representative_name)
      end

      step "submit conversion" do
        click_button("Convert Hearing To Virtual")
      end

      step "confirm page has the correct success message" do
        expect(page).to have_content(
          "You have successfully converted #{legacy_appeal.veteran_full_name}'s hearing to virtual"
        )
        expect(page).to have_content(
          "The hearing request is in the scheduling queue for the appropriate regional office"
        )
      end

      step "cnofirm schedule veteran task is actionable" do
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
      end
    end
  end

  context "without FeatureToggle enabled" do
    scenario "it does not create the ChangeHearingRequestTypeTask" do
      visit "queue/appeals/#{legacy_appeal.vacols_id}"

      expect(page).not_to have_content(ScheduleHearingTask.label)
      expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)
      expect(ChangeHearingRequestTypeTask.count).to eq(0)
    end
  end
end

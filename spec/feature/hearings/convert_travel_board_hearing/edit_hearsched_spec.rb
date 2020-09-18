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
      vacols_case: vacols_case
    )
  end

  context "with FeatureToggle enabled" do
    before do
      FeatureToggle.enable!(:convert_travel_board_to_video_or_virtual)
    end

    after do
      FeatureToggle.disable!(:convert_travel_board_to_video_or_virtual)
    end

    scenario "it creates a ChangeHearingRequestTypeTask" do
      visit "queue/appeals/#{legacy_appeal.vacols_id}"

      expect(page).to have_content(ScheduleHearingTask.label)
      expect(page).to have_content(ChangeHearingRequestTypeTask.label)
      click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)
      expect(ChangeHearingRequestTypeTask.count).to eq(1)
      expect(ChangeHearingRequestTypeTask.first.appeal.vacols_id).to eq(legacy_appeal.vacols_id)
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

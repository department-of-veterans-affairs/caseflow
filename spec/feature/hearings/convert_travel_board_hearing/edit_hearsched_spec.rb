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

      step "confirm schedule veteran task is actionable" do
        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
      end
    end

    context "with schedule veteran page feature toggle enabled" do
      before do
        FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
      end

      after do
        FeatureToggle.disable!(:schedule_veteran_virtual_hearing)
      end

      scenario "pre-selects virtual type on schedule veteran page" do
        visit "queue/appeals/#{legacy_appeal.vacols_id}"

        step "change hearing request type to virtual" do
          click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)

          click_button("Convert Hearing To Virtual")
        end

        step "work schedule veteran task" do
          click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
        end

        step "confirm virtual type is selected" do
          expect(
            page.find(".dropdown-hearingType").find(".cf-select__single-value")
          ).to have_content("Virtual")
        end
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

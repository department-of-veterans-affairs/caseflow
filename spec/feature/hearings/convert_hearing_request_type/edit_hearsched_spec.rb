# frozen_string_literal: true

RSpec.feature "Convert hearing request type" do
  let!(:vacols_case) do
    create(
      :case,
      :type_original,
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
  let(:video_appeal) do
    create(
      :appeal,
      :with_schedule_hearing_tasks,
      docket_type: Constants.AMA_DOCKETS.hearing,
      closest_regional_office: "RO39",
      veteran: create(:veteran)
    )
  end
  let(:central_office_appeal) do
    create(
      :appeal,
      :with_schedule_hearing_tasks,
      docket_type: Constants.AMA_DOCKETS.hearing,
      closest_regional_office: "C",
      veteran: create(:veteran)
    )
  end
  let!(:hearing_days) do
    [
      create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days, regional_office: "RO17"),
      create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days),
      create(:hearing_day, scheduled_for: Time.zone.today + 8.days)
    ]
  end

  def change_request_type(appeal, request_type, ro_message)
    step "select change hearing request type action" do
      click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)
    end

    step "ensure page has veteran and representative info" do
      expect(page).to have_content(appeal.veteran_full_name)
      expect(page).to have_content(appeal.representative_name)
    end

    step "submit conversion" do
      click_button("Convert Hearing To Virtual")
    end

    step "confirm page has the correct success message" do
      expect(page).to have_content(
        "You have successfully converted #{appeal.veteran_full_name}'s hearing to Virtual"
      )
      expect(page).to have_content(
        "The hearing request is in the scheduling queue for the #{ro_message}"
      )
    end

    step "confirm timeline displays relevant info about the completion of ChangeHearingRequestTypeTask" do
      within("table#case-timeline-table") do
        expect(page).to have_content(COPY::TASK_SNAPSHOT_HEARING_REQUEST_CONVERTED_ON_LABEL.upcase)
        expect(page).to have_content(COPY::TASK_SNAPSHOT_HEARING_REQUEST_CONVERTER_LABEL.upcase)
        expect(page).to have_content(
          "Hearing type converted from #{request_type} to Virtual"
        )
      end
    end

    step "confirm schedule veteran task is actionable" do
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
    end

    step "cancel the step that starts the schedule workflow to test the next step" do
      click_button("Cancel")
    end

    step "ensure the convert hearing action is no longer present, but task created" do
      expect(ChangeHearingRequestTypeTask.count).to eq(1)
      expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)
    end
  end

  context "for 'Edit HearSched' (Hearing Coordinator)" do
    let!(:current_user) { User.authenticate!(roles: ["Edit HearSched"]) }

    before do
      HearingsManagement.singleton.add_user(current_user)
    end

    context "When converting travel board appeal" do
      let!(:dispatched_vacols_case) do
        create(
          :case,
          bfmpro: "HIS",
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

        change_request_type(legacy_appeal, "Travel", "appropriate regional office")
      end

      scenario "user can cancel the ChangeHearingRequestTypeTask" do
        visit "queue/appeals/#{legacy_appeal.vacols_id}"

        step "select the cancel change hearing request type action" do
          click_dropdown(text: Constants.TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)
        end

        step "submit action" do
          click_button("Submit")
        end

        step "confirm page has success message" do
          expect(page).to have_content(COPY::CANCEL_CONVERT_HEARING_TYPE_TO_VIRTUAL_SUCCESS_DETAIL)
        end

        step "confirm hearing tasks were cancelled" do
          expect(ChangeHearingRequestTypeTask.count).to eq(1)
          expect(ChangeHearingRequestTypeTask.first.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(ScheduleHearingTask.count).to eq(1)
          expect(ScheduleHearingTask.first.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(HearingTask.count).to eq(1)
          expect(HearingTask.first.status).to eq(Constants.TASK_STATUSES.cancelled)
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

      context "with national virtual hearing queue feature toggle enabled" do
        before do
          FeatureToggle.enable!(:national_vh_queue)
        end

        after do
          FeatureToggle.disable!(:national_vh_queue)
        end

        let!(:hearing_days) do
          [
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today + 7.days),
            create(:hearing_day, :virtual, scheduled_for: Time.zone.today + 8.days)
          ]
        end

        scenario "appears in virtual hearings national queue" do
          visit "queue/appeals/#{legacy_appeal.vacols_id}"

          step "change hearing request type to virtual" do
            click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.label)

            click_button("Convert Hearing To Virtual")
          end

          step "go to schedule veterans page" do
            visit "hearings/schedule/assign"

            click_dropdown(text: "Virtual Hearings")
          end

          step "go to legacy hearings tab" do
            click_button("Legacy Veterans Waiting")

            expect(page).to have_content(legacy_appeal.docket_number)
          end
        end
      end
    end

    context "When converting appeal with Video hearing request type" do
      scenario "user can change a hearing request from Video to Virtual" do
        visit "queue/appeals/#{video_appeal.uuid}"

        change_request_type(video_appeal, "Video", "Denver regional office")
      end

      scenario "user can change a hearing request from Video to Central" do
        visit "queue/appeals/#{video_appeal.uuid}"

        # Select the Convert hearing to Central action
        click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_CENTRAL.label)

        # CHeck the Modal content and confirm the conversion
        expect(page).to have_content("Central Office")
        click_button("Convert Hearing to Central")

        # Check t
        expect(page).to have_content(
          "You have successfully converted #{video_appeal.veteran_full_name}'s hearing to Central"
        )
        expect(page).to have_content(
          "The hearing request is in the scheduling queue for the Central Office"
        )

        within("table#case-timeline-table") do
          expect(page).to have_content(COPY::TASK_SNAPSHOT_HEARING_REQUEST_CONVERTED_ON_LABEL.upcase)
          expect(page).to have_content(COPY::TASK_SNAPSHOT_HEARING_REQUEST_CONVERTER_LABEL.upcase)
          expect(page).to have_content(
            "Hearing type converted from Video to Central"
          )
        end

        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
        click_button("Cancel")

        expect(ChangeHearingRequestTypeTask.count).to eq(1)
        expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)

        # Check the schedule veterans tab to ensure the hearing is present
        visit "hearings/schedule/assign"

        click_dropdown(text: "Central")
        click_button("AMA Veterans Waiting")

        expect(page).to have_content(video_appeal.docket_number)
      end
    end

    context "When converting appeal with Central Office hearing request type" do
      scenario "user can change a hearing request from Central Office to Virtual" do
        visit "queue/appeals/#{central_office_appeal.uuid}"

        change_request_type(central_office_appeal, "Central", "Central Office")
      end

      scenario "user can change a hearing request from Central Office to Video" do
        # Set the converion text
        convert_label = COPY::CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT
        visit "queue/appeals/#{central_office_appeal.uuid}"

        click_dropdown(text: Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIDEO.label)

        # CHeck the Modal content and confirm the conversion
        expect(page).to have_content(convert_label)
        click_button("Convert Hearing to Video")

        # Check t
        expect(page).to have_content(
          "You have successfully converted #{central_office_appeal.veteran_full_name}'s hearing to Video"
        )
        expect(page).to have_content("The hearing request is in the scheduling queue for the #{convert_label}")

        within("table#case-timeline-table") do
          expect(page).to have_content(COPY::TASK_SNAPSHOT_HEARING_REQUEST_CONVERTED_ON_LABEL.upcase)
          expect(page).to have_content(COPY::TASK_SNAPSHOT_HEARING_REQUEST_CONVERTER_LABEL.upcase)
          expect(page).to have_content(
            "Hearing type converted from Central to Video"
          )
        end

        click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
        click_button("Cancel")

        expect(ChangeHearingRequestTypeTask.count).to eq(1)
        expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)

        # Check the schedule veterans tab to ensure the hearing is present
        visit "hearings/schedule/assign"

        click_dropdown(text: "St. Petersburg, FL")
        click_button("AMA Veterans Waiting")

        expect(page).to have_content(central_office_appeal.docket_number)
      end
    end
  end

  context "for all other users" do
    let!(:current_user) { User.authenticate! }

    context "When converting travel board appeal" do
      scenario "it does not create the ChangeHearingRequestTypeTask" do
        visit "queue/appeals/#{legacy_appeal.vacols_id}"

        expect(page).not_to have_content(ScheduleHearingTask.label)
        expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)
        expect(ChangeHearingRequestTypeTask.count).to eq(0)
      end
    end

    context "When converting appeal with Video hearing request type" do
      scenario "it shows the schedule veteran action but not the convert to virtual action" do
        visit "queue/appeals/#{video_appeal.uuid}"

        expect(page).to have_content(ScheduleHearingTask.label)
        expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)
        expect(ChangeHearingRequestTypeTask.count).to eq(0)
      end
    end

    context "When converting appeal with Central Office hearing request type" do
      scenario "it shows the schedule veteran action but not the convert to virtual action" do
        visit "queue/appeals/#{central_office_appeal.uuid}"

        expect(page).to have_content(ScheduleHearingTask.label)
        expect(page).not_to have_content(ChangeHearingRequestTypeTask.label)
        expect(ChangeHearingRequestTypeTask.count).to eq(0)
      end
    end
  end
end

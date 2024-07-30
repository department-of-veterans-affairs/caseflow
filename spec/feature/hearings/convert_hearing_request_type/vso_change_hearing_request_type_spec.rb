# frozen_string_literal: true

RSpec.feature "Convert hearing request type" do
  before do
    FeatureToggle.enable!(:vso_virtual_opt_in)
    FeatureToggle.enable!(:schedule_veteran_virtual_hearing)
    HearingsManagement.singleton.add_user(hearing_coord)
    vso.add_user(vso_user)

    allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
      [{ participant_id: vso_participant_id }]
    )
  end

  after do
    FeatureToggle.disable!(:vso_virtual_opt_in)
    FeatureToggle.disable!(:schedule_veteran_virtual_hearing)
  end

  let!(:hearing_day) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 14.days, regional_office: "RO63") }
  let!(:hearing_day2) { create(:hearing_day, :video, scheduled_for: Time.zone.today + 7.days, regional_office: "RO63") }
  let!(:vso_participant_id) { "8054" }
  let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: vso_participant_id) }
  let!(:vso_user) { create(:user, :vso_role, email: "DefinitelyNotNull@All.com") }
  let!(:hearing_coord) { create(:user, roles: ["Edit HearSched", "Build HearSched"]) }

  def appellant_name
    if appeal.is_a?(Appeal)
      "#{appeal.appellant.first_name} #{appeal.appellant.last_name}"
    else
      "#{appeal.appellant[:first_name]} #{appeal.appellant[:last_name]}"
    end
  end

  def timezone_label_by_value(timezone_value)
    Constants.TIMEZONES.to_h.key(timezone_value)
  end

  def expected_field_values
    expected_values = [
      appellant_name,
      timezone_label_by_value(appeal.appellant_tz),
      timezone_label_by_value(appeal.representative_tz),
      vso_user.email
    ]

    if appeal.is_a?(Appeal)
      expected_values.concat([
                               poa.representative_name,
                               poa.representative_type
                             ])
    else
      expected_values.concat([
                               poa.bgs_representative_name,
                               poa.bgs_representative_type
                             ])
    end
  end

  def verify_form_pre_population
    expected_field_values.compact.each do |field_value|
      expect(page).to have_content(field_value)
    end

    if appeal.is_a?(Appeal)
      expect(page).to have_field("Appellant Email", with: appeal.appellant.email_address)
    end
  end

  shared_examples "unscheduled hearings" do
    context "When appeal has no scheduled hearings" do
      scenario "convert to virtual link appears and leads to task form" do
        step "navigate to the VSO Form" do
          User.authenticate!(user: vso_user)
          visit "queue/appeals/#{appeal.external_id}"
          expect(page).to have_content("Video")
          click_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
        end

        step "verify pre-population of Queue form fields and submit it" do
          # Check if button is disabled on page load
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

          # Affirm checkboxes first to test other fields
          click_label("Affirm Permission")
          click_label("Affirm Access")

          # Check if buttone remains disabled
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

          # Fill out email field and expect validation message on invalid email
          fill_in "#{appellant_title} Email", with: "appellant@test.c"
          find("body").click
          expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL)
          fill_in "#{appellant_title} Email", with: "appellant@test.com"

          # Check if button remains disabled
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

          fill_in "Confirm #{appellant_title} Email", with: "appellant@not-matching"
          find("body").click
          expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
          fill_in "Confirm #{appellant_title} Email", with: "appellant@test.com"
          expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)

          # Set appellant tz to null
          click_dropdown(name: "appellantTz", index: 0)

          # Check if button remains disabled
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

          # Set rep tz to null
          click_dropdown(name: "representativeTz", index: 0)

          # Check if button remains disabled
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

          # Set appellant and rep timezones to something not null
          click_dropdown(name: "appellantTz", index: 1)
          click_dropdown(name: "representativeTz", index: 2)
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: false)

          # Alter original email to make sure that the confirm email validation picks up on the change.
          fill_in "#{appellant_title} Email", with: "valid@something-different.com"
          expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
          expect(page).to have_button("button-Convert-Hearing-To-Virtual", disabled: true)

          fill_in "#{appellant_title} Email", with: "appellant@test.com"
          expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)

          click_button("Convert Hearing To Virtual")
        end

        step "Confirm success message" do
          expect(page).to have_content(
            "You have successfully converted #{appellant_name}'s hearing to virtual"
          )
          expect(page).to have_content(COPY::VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL)
        end
      end
    end
  end

  shared_examples "scheduled hearings" do
    scenario "Navigating to the hearing details page and converting the hearing" do
      step "navigating to the hearing details page takes VSO user to conversion form" do
        User.authenticate!(user: vso_user)
        hearing_id = hearing.is_a?(Hearing) ? hearing.uuid : hearing.vacols_id
        visit "hearings/#{hearing_id}/details"
        expect(page).to have_content format(COPY::CONVERT_HEARING_TITLE, "Virtual")

        expect(hearing.appeal.changed_hearing_request_type).to_not eq(
          Constants.HEARING_REQUEST_TYPES.virtual
        )
      end

      step "verify pre-population of Hearings form fields" do
        verify_form_pre_population
      end

      step "test Hearings form validation and submit it" do
        # Check if button is disabled on page load
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)

        # Fill out email field and expect validation message on invalid email
        fill_in "#{appellant_title} Email", with: "appellant@test.c"
        find("body").click
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL)
        fill_in "#{appellant_title} Email", with: "appellant@test.com"

        # Check if button remains disabled
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)

        fill_in "Confirm #{appellant_title} Email", with: "appellant@not-matching"
        find("body").click
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
        fill_in "Confirm #{appellant_title} Email", with: "appellant@test.com"
        expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)

        # set appellant email to null
        fill_in "#{appellant_title} Email", with: ""
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)

        # fill appellant email back in
        fill_in "#{appellant_title} Email", with: "appellant@test.com"
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)

        click_label("affirmPermission")
        click_label("affirmAccess")

        # set appellantTz to null then not to null
        click_dropdown(name: "appellantTz", index: 0)
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)
        click_dropdown(name: "appellantTz", index: 1)
        expect(page).to have_button("Convert to Virtual Hearing", disabled: false)

        # set the representativeTz to null then not to null
        click_dropdown(name: "representativeTz", index: 0)
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)
        click_dropdown(name: "representativeTz", index: 2)
        expect(page).to have_button("Convert to Virtual Hearing", disabled: false)

        # Set appellant and rep timezones to something not null
        click_dropdown(name: "appellantTz", index: 1)
        click_dropdown(name: "representativeTz", index: 2)
        expect(page).to have_button("Convert to Virtual Hearing", disabled: false)

        # Alter original email to make sure that the confirm email validation picks up on the change.
        fill_in "#{appellant_title} Email", with: "valid@something-different.com"
        expect(page).to have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)
        expect(page).to have_button("Convert to Virtual Hearing", disabled: true)

        fill_in "#{appellant_title} Email", with: "appellant@test.com"
        expect(page).to_not have_content(COPY::CONVERT_HEARING_VALIDATE_EMAIL_MATCH)

        click_button "Convert to Virtual Hearing"
      end

      step "Confirm success message" do
        expect(page).to have_content(
          "You have successfully converted #{appellant_name}'s hearing to virtual"
        )
        expect(page).to have_content(COPY::VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL)

        # We only display hearing types for AMA hearings
        if hearing.is_a?(Hearing)
          expect(hearing.reload.appeal.changed_hearing_request_type).to eq(
            Constants.HEARING_REQUEST_TYPES.virtual
          )
        end
      end
    end
  end

  describe "for AMA appeals and hearings" do
    before { TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: vso) }

    let!(:appeal) do
      a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket, number_of_claimants: 1)
      a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video,
                veteran_is_not_claimant: true)
      a
    end
    let!(:poa) do
      create(:bgs_power_of_attorney,
             :with_name_cached,
             appeal: appeal,
             claimant_participant_id: appeal.claimant.participant_id)
    end
    let!(:appellant_title) { appeal.appellant_is_not_veteran ? "Appellant" : "Veteran" }

    context "whenever a hearing has not yet been scheduled" do
      it_behaves_like "unscheduled hearings"
    end

    context "whenever a hearing has been scheduled" do
      context "When appeal has a scheduled hearing in over 11 days" do
        scenario "convert to virtual link appears and leads to hearing form" do
          step "select from dropdown" do
            User.authenticate!(user: hearing_coord)
            visit "queue/appeals/#{appeal.uuid}"
            click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
          end

          step "fill in form" do
            fill_in "Notes", with: "asfsefdsfdf"
            click_dropdown(name: "regionalOffice", index: 1)
            click_dropdown(name: "appealHearingLocation", index: 0)
            click_dropdown(name: "hearingDate", index: 1)
            click_dropdown(name: "optionalHearingTime0", index: 0)
            click_button(text: "Schedule")
          end

          step "navigate to the hearings form" do
            appeal = Appeal.last
            User.authenticate!(user: vso_user)
            visit "queue/appeals/#{appeal.uuid}"
            expect(page).to have_content("Video")
            expect(page).to have_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
            click_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
            expect(page).to have_current_path("/hearings/#{appeal.hearings.first.uuid}/details")
          end
        end
      end

      context "When hearing is within 11 days of scheduled time" do
        scenario "info alert appears instead of link" do
          step "select from dropdown" do
            User.authenticate!(user: hearing_coord)
            visit "queue/appeals/#{appeal.uuid}"
            click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.label)
          end

          step "fill in form" do
            fill_in "Notes", with: "asfsefdsfdf"
            click_dropdown(name: "regionalOffice", index: 1)
            click_dropdown(name: "appealHearingLocation", index: 0)
            click_dropdown(name: "hearingDate", index: 0)
            click_dropdown(name: "optionalHearingTime0", index: 0)
            click_button(text: "Schedule")
          end

          step "vso user" do
            appeal = Appeal.last
            User.authenticate!(user: vso_user)
            visit "queue/appeals/#{appeal.uuid}"

            expect(page).not_to have_link(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
            expect(page).to have_link(
              "Contact the Hearing Coordinator to convert to virtual",
              href: "https://www.bva.va.gov/docs/RO_Coordinator_Assignments.pdf"
            )
            expect(page).to have_content(COPY::VSO_UNABLE_TO_CONVERT_TO_VIRTUAL_TEXT)
          end
        end
      end

      context "converting a scheduled hearing as a VSO user" do
        let!(:hearing) { create(:hearing, hearing_day: hearing_day, appeal: appeal) }

        it_behaves_like "scheduled hearings"
      end
    end

    context "whenever a VSO user from another organization" do
      before do
        different_vso.add_user(different_vso_user)
        allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
          [{ participant_id: different_vso_participant_id }]
        )
      end

      after do
        allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
          [{ participant_id: vso_participant_id }]
        )
      end

      let!(:hearing) { create(:hearing, hearing_day: hearing_day, appeal: appeal) }
      let!(:different_vso_user) { create(:user, :vso_role, email: "DefinitelyNotNull@All.com") }
      let!(:different_vso_participant_id) { "9999" }
      let!(:different_vso) do
        create(:vso,
               name: "Different VSO",
               role: "VSO",
               url: "vso2-url",
               participant_id: "different_vso_participant_id")
      end

      scenario "does not represent an appellant and attempts to access their hearing" do
        User.authenticate!(user: different_vso_user)

        visit "/hearings/#{hearing.uuid}/details"

        expect(page).to have_current_path "/unauthorized"
      end
    end
  end

  describe "for legacy appeals and hearings" do
    before { TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: vso) }

    let(:ssn) { Generators::Random.unique_ssn }
    let!(:vacols_case) { create(:case, :representative_american_legion) }
    let!(:appeal) do
      a = create(:legacy_appeal,
                 :with_schedule_hearing_tasks,
                 vacols_case: vacols_case)
      a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video)
      a
    end

    let!(:poa) { PowerOfAttorney.new(vacols_id: vacols_case.bfkey, file_number: "VBMS-ID") }
    let!(:appellant_title) { appeal.appellant_is_not_veteran ? "Appellant" : "Veteran" }

    context "whenever a legacy hearing has not yet been scheduled" do
      it_behaves_like "unscheduled hearings"
    end

    context "whenever a legacy hearing has been scheduled" do
      let!(:hearing) { create(:legacy_hearing, :for_vacols_case, hearing_day: hearing_day2, appeal: appeal) }

      it_behaves_like "scheduled hearings"

      context "whenever a user from another VSO users tries to access the hearing" do
        before do
          allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
            [{ participant_id: "12345" }]
          )
          User.authenticate!(roles: ["VSO"])
        end

        it "they are denied" do
          visit "/hearings/#{hearing.vacols_id}/details"

          expect(page).to have_current_path "/unauthorized"
        end
      end
    end
  end
end

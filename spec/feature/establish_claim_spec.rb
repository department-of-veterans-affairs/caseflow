require "rails_helper"

RSpec.feature "Dispatch" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1))

    @vbms_id = "VBMS_ID1"

    BGSService.end_product_data = [
      {
        benefit_claim_id: "1",
        claim_receive_date: (Time.zone.now - 20.days).to_formatted_s(:short_date),
        claim_type_code: "172GRANT",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: (Time.zone.now + 10.days).to_formatted_s(:short_date),
        claim_type_code: "170RMD",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now.to_formatted_s(:short_date),
        claim_type_code: "172BVAG",
        status_type_code: "CAN"
      },
      {
        benefit_claim_id: "4",
        claim_receive_date: (Time.zone.now - 200.days).to_formatted_s(:short_date),
        claim_type_code: "172BVAG",
        status_type_code: "CLR"
      }]

    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_full_grant_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided,
      "789E" => Fakes::AppealRepository.appeal_partial_grant_decided,
      @vbms_id => { documents: [Document.new(
        received_at: (Time.current - 7.days).to_date, type: "BVA Decision",
        vbms_document_id: "123"
      )]
      }
    }
    Fakes::AppealRepository.end_product_claim_id = "CLAIM_ID_123"

    appeal = Appeal.create(
      vacols_id: "123C",
      vbms_id: @vbms_id
    )
    @task = EstablishClaim.create(appeal: appeal)
    @task.prepare!

    appeal = Appeal.create(
      vacols_id: "789E",
      vbms_id: "new_vbms_id"
    )
    @task2 = EstablishClaim.create(appeal: appeal)
    @task2.prepare!

    allow(Fakes::AppealRepository).to receive(:establish_claim!).and_call_original
  end

  context "As a manager" do
    before do
      User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"])
      @task.assign!(:assigned, User.create(station_id: "123", css_id: "ABC"))

      create_tasks(20, initial_state: :completed)
    end

    scenario "View manager page" do
      visit "/dispatch/establish-claim"
      expect(page).to have_content("ARC Work Assignments")

      expect(page).to have_content("Number of people")
      fill_in "Number of people", with: "3"
      click_on "Update"
      visit "/dispatch/establish-claim"
      expect(find_field("Number of people").value).to have_content("3")

      # This looks for the row in the table for the User 'Jane Smith 0' who has
      # eight tasks assigned to her, has completed one, and has seven remaining.
      expect(page).to have_content("Jane Smith 0 8 1 7")
    end

    scenario "View unprepared tasks page" do
      @unprepared_appeal = Appeal.create(
        vacols_id: "456D",
        vbms_id: "VBMS_ID2"
      )
      @unprepared_task = EstablishClaim.create(appeal: @unprepared_appeal)

      visit "/dispatch/missing-decision"

      # should see the unprepared task
      expect(page).to have_content("Claims Missing Decisions")
      expect(page).to have_content(@unprepared_task.appeal.veteran_name)
    end
  end

  context "As a caseworker" do
    before do
      User.authenticate!(roles: ["Establish Claim"])

      # completed by user task
      appeal = Appeal.create(vacols_id: "456D")

      @completed_task = EstablishClaim.create(appeal: appeal)
      @completed_task.prepare!
      @completed_task.assign!(:assigned, current_user)
      @completed_task.start!
      @completed_task.review!
      @completed_task.complete!(:completed, status: 0)

      other_user = User.create(css_id: "some", station_id: "stuff")
      @other_task = EstablishClaim.create(appeal: Appeal.new(vacols_id: "asdf"))
      @other_task.prepare!
      @other_task.assign!(:assigned, other_user)
      @other_task.start!
    end

    context "Skip the associate EP page" do
      before do
        BGSService.end_product_data = []
      end

      scenario "Establish a new claim page and process pt1" do
        visit "/dispatch/establish-claim"

        # View history
        expect(page).to have_content("Establish Next Claim")
        expect(page).to have_css("thead")

        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

        # Can't start new task til current task is complete
        visit "/dispatch/establish-claim"
        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

        expect(page).to have_content("Review Decision")
        expect(@task.reload.user).to eq(current_user)
        expect(@task.started?).to be_truthy

        click_on "Route Claim"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(find(".cf-app-segment > h1")).to have_content("Create End Product")
      end

      scenario "Establish a new claim page and process pt2" do
        # Complete last task so that we can ensure there are no remaining tasks
        @task2.assign!(:assigned, current_user)
        @task2.start!
        @task2.review!
        @task2.complete!(:completed, status: 0)

        visit "/dispatch/establish-claim"
        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        # page.select "Full Grant", from: "decisionType"

        click_on "Route Claim"

        # Test text, radio button, & checkbox inputs
        find_label_for("gulfWarRegistry").click
        click_on "Create End Product"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Congratulations!")

        # We should not have this message on the congratulations page unless a special
        # issue was checked.
        expect(page).to_not have_content("Manually Added VBMS Note")

        expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
          claim: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: @task.appeal.decision_date.to_date,
            end_product_modifier: "172",
            end_product_label: "BVA Grant",
            end_product_code: "172BVAG",
            gulf_war_registry: true,
            suppress_acknowledgement_letter: false
          },
          appeal: @task.appeal
        )
        expect(@task.reload.completed?).to be_truthy
        expect(@task.completion_status).to eq(0)
        expect(@task.outgoing_reference_id).to eq("CLAIM_ID_123")

        expect(@task.appeal.reload.dispatched_to_station).to eq("397")

        click_on "Caseflow Dispatch"
        expect(page).to have_current_path("/dispatch/establish-claim")

        # No tasks left
        expect(page).to have_content("There are no more claims in your queue")
        expect(page).to have_css(".usa-button-disabled")
      end

      scenario "Establish a new claim with special issues" do
        visit "/dispatch/establish-claim"

        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

        # Select special issues
        find_label_for("riceCompliance").click
        find_label_for("privateAttorneyOrAgent").click

        # Move on to note page
        click_on "Route Claim"
        click_on "Create End Product"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(find(".cf-app-segment > h2")).to have_content("Route Claim")

        # Make sure note page contains the special issues
        expect(find_field("VBMS Note").value).to have_content("Private Attorney or Agent, and Rice Compliance")

        # Ensure that the user stays on the note page on a refresh
        visit "/dispatch/establish-claim/#{@task.id}"
        expect(find(".cf-app-segment > h2")).to have_content("Route Claim")
        find_label_for("confirmNote").click

        click_on "Finish Routing Claim"

        expect(page).to have_content("Manually Added VBMS Note")
        expect(@task.appeal.reload.rice_compliance).to be_truthy
      end

      skip "Establish Claim form saves state when going back/forward in browser" do
        @task.assign!(:assigned, current_user)
        visit "/dispatch/establish-claim/#{@task.id}"
        click_on "Create End Product"
        expect(page).to have_content("Benefit Type") # React works

        # page.go_back_in_browser (pseudocode)

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Review Decision")

        click_on "Create End Product"
      end

      context "Multiple decisions in VBMS" do
        before do
          Fakes::AppealRepository.records = {
            "123C" => Fakes::AppealRepository.appeal_remand_decided,
            "456D" => Fakes::AppealRepository.appeal_remand_decided,
            @vbms_id => { documents: [Document.new(
              received_at: (Time.current - 7.days).to_date, type: "BVA Decision",
              vbms_document_id: "123"
            ), Document.new(
              received_at: (Time.current - 6.days).to_date, type: "BVA Decision",
              vbms_document_id: "456"
            )
            ] }
          }
        end

        scenario "review page lets users choose which to use" do
          visit "/dispatch/establish-claim"
          click_on "Establish Next Claim"

          # View history
          expect(page).to have_content("Multiple Decision Documents")

          # Text on the tab
          expect(page).to have_content("Decision 1 (")
          find("#tab-1").click
          expect(page).to have_content("Route Claim for Decision 2")
          click_on "Route Claim for Decision 2"

          expect(page).to have_content("Benefit Type")
        end
      end
    end

    context "Add existing Full Grant & Partial Grant EPs" do
      before do
        BGSService.end_product_data =
          [
            {
              benefit_claim_id: "1",
              claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
              claim_type_code: "172GRANT",
              end_product_type_code: "172",
              status_type_code: "PEND"
            },
            {
              benefit_claim_id: "2",
              claim_receive_date: 10.days.from_now.to_formatted_s(:short_date),
              claim_type_code: "170RMD",
              end_product_type_code: "170",
              status_type_code: "PEND"
            }
          ]
      end

      context "Unavailable modifiers" do
        scenario "full grants" do
          # Test that the full grant associate page disables the Create New EP button
          visit "/dispatch/establish-claim"
          click_on "Establish Next Claim"
          expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

          click_on "Route Claim"
          expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
          expect(page).to have_content("EP & Claim Label Modifiers in use")

          expect(page.find("#button-Create-New-EP")[:class]).to include("usa-button-disabled")
        end

        scenario "partial grants" do
          # Complete first task so that we can get partial grant assigned to us
          @task.assign!(:assigned, current_user)
          @task.start!
          @task.review!
          @task.complete!(:completed, status: 0)

          # Test that for a partial grant, the list of available modifiers is restricted
          # to unused modifiers.
          visit "/dispatch/establish-claim"
          click_on "Establish Next Claim"
          click_on "Route Claim"

          click_on "Create New EP"

          date = "01/08/2017"
          page.fill_in "Decision Date", with: date

          click_on "Create End Product"

          expect(page).to have_current_path("/dispatch/establish-claim/#{@task2.id}")
          expect(page).to have_content("Congratulations!")

          expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
            claim: {
              benefit_type_code: "1",
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              date: @task2.appeal.decision_date.to_date,
              end_product_modifier: "171",
              end_product_label: "AMC-Partial Grant",
              end_product_code: "170PGAMC",
              station_of_jurisdiction: "397",
              gulf_war_registry: false,
              suppress_acknowledgement_letter: false
            },
            appeal: @task2.appeal
          )
        end
      end
    end

    scenario "Associate existing claim with decision" do
      visit "/dispatch/establish-claim"
      click_on "Establish Next Claim"
      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

      # set special issue to ensure it is saved in the database
      find_label_for("mustardGas").click

      click_on "Route Claim"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_content("Existing EP")

      page.find("#button-Assign-to-Claim1").click

      expect(page).to have_content("Congratulations!")

      expect(@task.reload.completion_status)
        .to eq(Task.completion_status_code(:assigned_existing_ep))
      expect(@task.reload.outgoing_reference_id).to eq("1")
      expect(@task.appeal.reload.mustard_gas).to be_truthy
    end

    scenario "Visit an Establish Claim task that is assigned to another user" do
      visit "/dispatch/establish-claim/#{@other_task.id}"
      expect(page).to have_current_path("/unauthorized")
    end

    # The cancel button is the same on both the review and form pages, so one test
    # can adequetly test both of them.
    scenario "Cancel an Establish Claim task returns me to landing page" do
      @task.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{@task.id}"

      # click on special issue
      find_label_for("riceCompliance").click

      # Open modal
      click_on "Cancel"
      expect(page).to have_css(".cf-modal")

      # Try to cancel without explanation
      click_on "Stop processing claim"
      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_css(".cf-modal")
      expect(page).to have_content("Please enter an explanation")

      # Close modal
      click_on "Close"
      expect(page).to_not have_css(".cf-modal")

      # Open modal
      click_on "Cancel"
      expect(page).to have_css(".cf-modal")

      # Fill in explanation and cancel
      page.fill_in "Explanation", with: "Test"
      click_on "Stop processing claim"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_content("Claim Processing Discontinued")
      expect(@task.reload.completed?).to be_truthy
      expect(@task.appeal.tasks.where(type: :EstablishClaim).to_complete.count).to eq(0)
      expect(@task.comment).to eq("Test")

      # The special issue should not be saved on cancel
      expect(@task.appeal.reload.rice_compliance).to be_falsey
    end

    scenario "An unhandled special issue routes to email page" do
      @task.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{@task.id}"
      find_label_for("dicDeathOrAccruedBenefitsUnitedStates").click
      click_on "Route Claim"
      expect(page).to have_content("We are unable to create an EP for claims with this Special Issue")
      find_label_for("confirmEmail").click
      click_on "Finish Routing Claim"
      expect(page).to have_content("Sent email notification")
    end

    scenario "An unhandled special issue with no email routes to no email page" do
      @task.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{@task.id}"
      find_label_for("vocationalRehab").click
      click_on "Route Claim"
      expect(page).to have_content("Please process this claim manually")
      find_label_for("confirmEmail").click
      click_on "Release Claim"
      expect(page).to have_content("Processed case outside of Caseflow")
    end

    scenario "A regional office special issue routes correctly" do
      @task.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{@task.id}"
      find_label_for("mustardGas").click

      # It should also work even if a unsupported special issue is checked
      find_label_for("dicDeathOrAccruedBenefitsUnitedStates").click

      click_on "Route Claim"
      click_on "Create New EP"
      expect(find_field("Station of Jurisdiction").value).to eq("351 - Muskogee, OK")

      click_on "Create End Product"
      find_label_for("confirmNote").click
      click_on "Finish Routing Claim"

      expect(page).to have_content("Congratulations!")
      expect(@task.appeal.reload.dispatched_to_station).to eq("351")
    end

    scenario "A national office special issue routes correctly" do
      @task2.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{@task2.id}"
      find_label_for("mustardGas").click
      click_on "Route Claim"
      click_on "Create New EP"
      expect(find_field("Station of Jurisdiction").value).to eq("351 - Muskogee, OK")
    end
  end
end

require "rails_helper"

RSpec.feature "Establish Claim - ARC Dispatch" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1))

    BGSService.end_product_data = []

    allow(Fakes::AppealRepository).to receive(:establish_claim!).and_call_original
    allow(Fakes::AppealRepository).to receive(:update_vacols_after_dispatch!).and_call_original
  end

  let(:case_worker) do
    User.create(station_id: "123", css_id: "JANESMITH", full_name: "Jane Smith")
  end

  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
  end

  let(:documents) do
    [Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)]
  end

  let(:vacols_record) { :remand_decided }

  context "As a manager" do
    let!(:current_user) do
      User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"])
    end

    scenario "View manager page" do
      # Create 4 incomplete tasks and one completed today
      4.times { Generators::EstablishClaim.create(aasm_state: :unassigned) }
      Generators::EstablishClaim.create(
        user_id: case_worker.id,
        aasm_state: :completed,
        completed_at: Time.zone.now
      )

      visit "/dispatch/establish-claim"
      expect(page).to have_content("ARC Work Assignments")

      fill_in "the number of people", with: "2"
      safe_click_on "Update"
      visit "/dispatch/establish-claim"
      expect(find_field("the number of people").value).to have_content("2")

      # This looks for the row in the table for the User 'Jane Smith' who has
      # two tasks assigned to her, has completed one, and has one remaining.
      expect(page).to have_content("Jane Smith 3 1 2")
      expect(page).to have_content("Employee Total 5 1 4")
    end

    scenario "View unprepared tasks page" do
      unprepared_task = Generators::EstablishClaim.create(aasm_state: :unprepared)

      visit "/dispatch/missing-decision"

      # should see the unprepared task
      expect(page).to have_content("Claims Missing Decisions")
      expect(page).to have_content(unprepared_task.appeal.veteran_name)
    end
  end

  context "As a caseworker" do
    let!(:current_user) { User.authenticate!(roles: ["Establish Claim"]) }

    let!(:task) do
      Generators::EstablishClaim.create(
        created_at: 3.days.ago,
        appeal_id: appeal.id,
        aasm_state: "unassigned"
      )
    end

    let(:invalid_appeal) do
      Generators::Appeal.create(
        vacols_record: { template: :remand_decided, decision_date: nil },
        documents: documents
      )
    end

    let(:inaccessible_appeal) do
      Generators::Appeal.create(vacols_record: vacols_record, inaccessible: true)
    end

    let(:ep_already_exists_error) do
      VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
        "A duplicate claim for this EP code already exists in CorpDB. Please " \
        "use a different EP code modifier. GUID: 13fcd</faultstring>")
    end

    let(:missing_ssn_error) do
      VBMS::HTTPError.new("500", "<fieldName>PersonalInfo SSN</fieldName>" \
        "<errorType>MINIMUM_LENGTH_NOT_SATISFIED</errorType><message>The " \
        "minimum data length for the PersonalInfo SSN within the veteran " \
        "was not satisfied: The PersonalInfo SSN must not be empty." \
        "</message></formFieldErrors>")
    end

    scenario "Assign the correct new task to myself" do
      # Create an older task with an inaccessible appeal
      Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        aasm_state: :unassigned,
        appeal: inaccessible_appeal
      )

      # Create a task already assigned to another user
      Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        user_id: case_worker.id,
        aasm_state: :started
      )

      # Create a task already completed by me
      completed_task = Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        user_id: current_user.id,
        aasm_state: :completed,
        completion_status: :special_issue_vacols_routed
      )

      # Create an invalid task, this should be invalidated and skipped
      invalid_task = Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        aasm_state: :unassigned,
        appeal: invalid_appeal
      )

      visit "/dispatch/establish-claim"

      # Validate completed task is in view history (along with the header, totaling 2 tr's)
      expect(page).to have_selector('#work-history-table tr', count: 2)
      expect(page).to have_content("(#{completed_task.appeal.sanitized_vbms_id})")
      expect(page).to have_content("Routed in VACOLS")

      # The oldest task (task local var) is now set to a higher security level so
      # it will be skipped for task_with_access
      safe_click_on "Establish next claim"

      # Validate the unassigned task was assigned to me
      expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
      expect(task.reload.user).to eq(current_user)
      expect(task).to be_started

      # Validate that a Claim Establishment object was created
      expect(task.claim_establishment.outcoding_date).to eq(appeal.outcoding_date)
      expect(task.claim_establishment).to be_remand

      # Validate the invalid task was invalidated
      expect(invalid_task.reload).to be_invalidated

      visit "/dispatch/establish-claim"
      safe_click_on "Establish next claim"

      # Validate I cannot assign myself a new task before completing the old one
      expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
    end

    scenario "Visit an Establish Claim task that is assigned to another user" do
      not_my_task = Generators::EstablishClaim.create(user_id: case_worker.id, aasm_state: :started)

      visit "/dispatch/establish-claim/#{not_my_task.id}"
      expect(page).to have_current_path("/unauthorized")
    end

    scenario "Go back and forward in the browser" do
      task.assign!(:assigned, current_user)

      visit "/dispatch/establish-claim/#{task.id}"

      safe_click_on "Route claim"

      find_label_for("gulfWarRegistry").click
      expect(page).to have_content("Create End Product")

      page.go_back

      expect(page).to have_content("Review Decision")

      safe_click_on "Route claim"

      expect(page).to have_content("Create End Product")

      # Validate that the state was saved from the earlier checkbox click
      expect(find("#gulfWarRegistry", visible: false)).to be_checked
    end

    scenario "Cannot re-complete a completed task" do
      task.assign!(:assigned, current_user)
      task.start!(:started)

      visit "/dispatch/establish-claim/#{task.id}"

      task.complete!(status: 0)

      safe_click_on "Route claim"
      expect(page).to have_content("This task was already completed")
    end

    scenario "Cancel a claims establishment" do
      task.assign!(:assigned, current_user)

      # The cancel button is the same on both the review and form pages, so one test
      # can adequetly test both of them.
      visit "/dispatch/establish-claim/#{task.id}"
      find_label_for("riceCompliance").click
      safe_click_on "Cancel"

      expect(page).to have_css(".cf-modal")

      # Validate I can't cancel without entering an explanation
      safe_click_on "Stop processing claim"
      expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
      expect(page).to have_css(".cf-modal")
      expect(page).to have_content("Please enter an explanation")

      # Validate closing the cancellation modal
      safe_click_on "Close"
      expect(page).to_not have_css(".cf-modal")

      # Open modal
      safe_click_on "Cancel"
      expect(page).to have_css(".cf-modal")

      # Fill in explanation and cancel
      page.fill_in "Explanation", with: "Test"
      click_on "Stop processing claim"

      expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
      expect(page).to have_content("Claim Processing Discontinued")
      expect(task.reload).to be_completed
      expect(task.appeal.tasks.where(type: :EstablishClaim).to_complete.count).to eq(0)
      expect(task.comment).to eq("Test")

      # Validate special issue isn't saved on cancel
      expect(task.appeal.reload.rice_compliance).to be_falsey
    end

    scenario "Error establishing claim" do
      # Duplicate EP error
      allow(Appeal.repository).to receive(:establish_claim!).and_raise(ep_already_exists_error)

      task.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{task.id}"
      safe_click_on "Route claim"
      safe_click_on "Create End Product"

      expect(page).to_not have_content("Success!")
      expect(page).to have_content("An EP with that modifier was previously created for this claim.")

      # Missing SSN error
      allow(Appeal.repository).to receive(:establish_claim!).and_raise(missing_ssn_error)

      click_on "Create End Product"
      expect(page).to_not have_content("Success!")
      expect(page).to have_content("This veteran does not have a social security number")
    end

    context "For an appeal with multiple possible decision documents in VBMS" do
      let(:documents) do
        [
          Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago),
          Generators::Document.build(type: "BVA Decision", received_at: 6.days.ago)
        ]
      end

      scenario "Review page lets users choose which document to use" do
        visit "/dispatch/establish-claim"
        safe_click_on "Establish next claim"

        expect(page).to have_content("Multiple Decision Documents")

        # Text on the tab
        expect(page).to have_content("Decision 1 (")
        find("#main-tab-1").click

        expect(page).to have_content("Route claim for Decision 2")
        safe_click_on "Route claim for Decision 2"

        expect(page).to have_content("Benefit Type")
      end

      scenario "the EP creation page has a link back to decision review" do
        visit "/dispatch/establish-claim"
        safe_click_on "Establish next claim"

        expect(page).to have_content("Multiple Decision Documents")
        safe_click_on "Route claim for Decision 1"
        safe_click_on "< Back to Review Decision"
        expect(page).to have_content("Multiple Decision Documents")
      end
    end

    context "For a full grant" do
      let(:vacols_record) do
        # Specify RO to test ROJ routing
        { template: :full_grant_decided, regional_office_key: "RO21" }
      end

      scenario "Establish a new claim with special issue routed to national office" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        find_label_for("mustardGas").click

        # Validate it routes correctly even if an unsupported special issue is checked
        find_label_for("dicDeathOrAccruedBenefitsUnitedStates").click

        safe_click_on "Route claim"

        expect(find_field("Station of Jurisdiction").value).to eq("351 - Muskogee, OK")

        safe_click_on "Create End Product"
        find_label_for("confirmNote").click
        safe_click_on "Finish routing claim"

        expect(page).to have_content("Success!")
        expect(page).to have_content("Reviewed Full Grant decision")
        expect(page).to have_content("Established EP: 172BVAG - BVA Grant for Station 351 - Muskogee")

        expect(page).to have_content("There are no more claims in your queue")
        expect(page).to have_button("Establish next claim", disabled: true)

        expect(task.appeal.reload.dispatched_to_station).to eq("351")
        expect(task.reload.completion_status).to eq("routed_to_ro")
      end

      scenario "Establish a new claim with special issue routed to ROJ" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        find_label_for("riceCompliance").click
        safe_click_on "Route claim"

        expect(find_field("Station of Jurisdiction").value).to eq("321 - New Orleans, LA")

        safe_click_on "Create End Product"

        # Form Page
        expect(page).to have_content("Route Claim: Add VBMS Note")
        expect(find_field("VBMS Note").value).to have_content("Rice Compliance")

        # Validate I cannot return to Review Decision from the VACOLS Update page
        expect(page).to_not have_content("< Back to Review Decision")
        page.driver.go_back
        expect(page).to have_content("Cannot edit end product")

        find_label_for("confirmNote").click
        safe_click_on "Finish routing claim"

        # Confirmation Page
        expect(page).to have_content("Success!")
        expect(page).to have_content("Added VBMS Note on Rice Compliance")

        expect(task.reload.completion_status).to eq("routed_to_ro")
      end

      scenario "Establish a new claim with special issues by routing via email" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        find_label_for("dicDeathOrAccruedBenefitsUnitedStates").click
        safe_click_on "Route claim"

        # Validate I can return to Review Decision from the VACOLS Update page
        safe_click_on "< Back to Review Decision"
        safe_click_on "Route claim"

        expect(page).to have_content("We are unable to create an EP for claims with this Special Issue")

        find_label_for("confirmEmail").click
        safe_click_on "Finish routing claim"

        expect(page).to have_content("Sent email to: PMCAppeals.VBAMIW@va.gov, tammy.boggs@va.gov in " \
                                     "Milwaukee Pension Center, WI - re: DIC - death, or accrued benefits")

        expect(task.reload.completion_status).to eq("special_issue_emailed")
      end

      context "When there is an existing 172 EP" do
        before do
          BGSService.end_product_data = [
            {
              benefit_claim_id: "1",
              claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
              claim_type_code: "172GRANT",
              end_product_type_code: "172",
              status_type_code: "PEND"
            }
          ]
        end

        scenario "Assigning it to complete the claims establishment" do
          visit "/dispatch/establish-claim"
          safe_click_on "Establish next claim"
          expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

          # set special issue to ensure it is saved in the database
          find_label_for("mustardGas").click

          safe_click_on "Route claim"
          expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
          expect(page).to have_content("EP & Claim Label Modifiers in use")

          # Validate the full grant associate page disables the Create new EP button
          expect(page.find("#button-Create-new-EP")[:class]).to include("usa-button-disabled")

          page.find("#button-Assign-to-Claim1").click

          expect(page).to have_content("Congratulations!")

          task.reload
          expect(task.outgoing_reference_id).to eq("1")
          expect(task.appeal.reload.mustard_gas).to be_truthy
          expect(task.completion_status).to eq("assigned_existing_ep")
        end
      end
    end

    context "For a partial grant" do
      let(:vacols_record) { :partial_grant_decided }

      scenario "Establish a new claim routed to ARC" do
        # Mock the claim_id returned by VBMS's create end product
        Fakes::AppealRepository.end_product_claim_id = "CLAIM_ID_123"

        visit "/dispatch/establish-claim"
        # Decision Page
        safe_click_on "Establish next claim"

        expect(page).to have_content("Review Decision")
        expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

        # Validate the correct steps on the progress bar are activated
        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Decision")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "2. Route Claim")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Confirmation")

        safe_click_on "Route claim"

        expect(find(".cf-app-segment > h1")).to have_content("Create End Product")
        expect(find_field("Station of Jurisdiction").value).to eq "397 - ARC"

        # Test text, radio button, & checkbox inputs
        find_label_for("gulfWarRegistry").click
        safe_click_on "Create End Product"

        # Confirmation Page
        expect(page).to have_content("Success!")
        expect(page).to have_content("Established EP: 170PGAMC - ARC-Partial Grant for Station 397 - ARC")
        expect(page).to have_content("VACOLS Updated: Changed Location to 98")
        expect(page).to_not have_content("Added VBMS Note")
        expect(page).to_not have_content("Added Diary Note")

        # Validate the correct steps on the progress bar are activated
        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Decision")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Route Claim")
        expect(page).to have_css(".cf-progress-bar-activated", text: "3. Confirmation")

        expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: task.appeal.decision_date.to_date,
            end_product_modifier: "170",
            end_product_label: "ARC-Partial Grant",
            end_product_code: "170PGAMC",
            gulf_war_registry: true,
            suppress_acknowledgement_letter: true
          },
          veteran_hash: task.appeal.veteran.to_vbms_hash
        )

        expect(Fakes::AppealRepository).to have_received(:update_vacols_after_dispatch!)

        expect(task.reload.completed?).to be_truthy
        expect(task.completion_status).to eq("routed_to_arc")
        expect(task.outgoing_reference_id).to eq("CLAIM_ID_123")

        expect(task.appeal.reload.dispatched_to_station).to eq("397")

        click_on "Caseflow Dispatch"
        expect(page).to have_current_path("/dispatch/establish-claim")

        # No tasks left
        expect(page).to have_content("There are no more claims in your queue")
        expect(page).to have_css(".usa-button-disabled")
      end

      scenario "Establish a new claim with special issues" do
        visit "/dispatch/establish-claim"

        safe_click_on "Establish next claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

        # Select special issues
        find_label_for("riceCompliance").click
        find_label_for("privateAttorneyOrAgent").click

        # Move on to note page
        safe_click_on "Route claim"

        expect(page).to have_content("Create End Product")

        # Test that special issues were saved
        expect(task.appeal.reload.rice_compliance).to be_truthy

        safe_click_on "Create End Product"

        expect(page).to have_content("Route Claim: Confirm VACOLS Update, Add VBMS Note")

        # Validate we cannot go back
        expect(page).to_not have_content("< Back to Review Decision")
        page.driver.go_back
        expect(page).to have_content("Cannot edit end product")

        # Make sure note page contains the special issues
        expect(find_field("VBMS Note").value).to have_content("Private Attorney or Agent, and Rice Compliance")

        # Validate special issue text within vacols note
        expect(page).to have_content("Private Attorney or Agent, Rice Compliance")

        # Validate note page shows correct decision type for claim in vbms note
        expect(find_field("VBMS Note").value).to have_content("The BVA Partial Grant decision")

        # Validate note page shows correct decision type for claim in vacols diary note
        expect(page).to have_content("Add the diary note: The BVA Partial Grant decision")

        # Validate correct vacols location
        expect(page).to have_content("50")

        # Ensure that the user stays on the note page on a refresh
        visit "/dispatch/establish-claim/#{task.id}"

        expect(find(".cf-app-segment > h2")).to have_content("Route Claim")
        find_label_for("confirmNote").click

        safe_click_on "Finish routing claim"

        expect(page).to have_content("Success!")
        expect(page).to have_content("VACOLS Updated: Changed Location to 50")
        expect(page).to have_content("Added VBMS Note on Private Attorney or Agent; Rice Compliance")
        expect(page).to have_content("VACOLS Updated: Added Diary Note on Private Attorney or Agent; Rice Compliance")

        expect(task.appeal.reload.rice_compliance).to be_truthy
        expect(task.reload.completion_status).to eq("routed_to_ro")

        expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "313",
            date: task.appeal.decision_date.to_date,
            end_product_modifier: "170",
            end_product_label: "Remand with BVA Grant",
            end_product_code: "170RBVAG",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: true
          },
          veteran_hash: task.appeal.veteran.to_vbms_hash
        )
      end

      scenario "Establish a new claim with special issues with no EP" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        find_label_for("dicDeathOrAccruedBenefitsUnitedStates").click
        safe_click_on "Route claim"

        expect(page).to have_content("Route Claim: Confirm VACOLS Update")

        # Validate special issue text within vacols note
        expect(page).to have_content("DIC - death, or accrued benefits")

        # Validate no VBMS-related content
        expect(page).to_not have_content("Update VACOLS and VBMS")

        # Validate I can return to Review Decision from the VACOLS Update page
        expect(page).to have_content("< Back to Review Decision")
        safe_click_on "< Back to Review Decision"
        safe_click_on "Route claim"

        # Valdiate correct vacols location
        expect(page).to have_content("50")

        safe_click_on "Finish routing claim"

        expect(page).to have_content("Success!")
        expect(task.reload.completion_status).to eq("special_issue_vacols_routed")
      end

      context "When there is an existing 170 EP" do
        before do
          BGSService.end_product_data = [
            {
              benefit_claim_id: "2",
              claim_receive_date: 10.days.from_now.to_formatted_s(:short_date),
              claim_type_code: "170RMD",
              end_product_type_code: "170",
              status_type_code: "PEND"
            }
          ]
        end

        scenario "Establish a new claim defaults to creating a 171 EP" do
          visit "/dispatch/establish-claim"
          safe_click_on "Establish next claim"
          safe_click_on "Route claim"

          expect(page).to have_content("Existing EP")

          # Validate the Back link takes you back to the Review Decision page
          safe_click_on "< Back to Review Decision"

          expect(page).to have_content("Review Decision")

          safe_click_on "Route claim"
          safe_click_on "Create new EP"
          safe_click_on "Create End Product"

          expect(page).to have_content("Success!")

          expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
            claim_hash: {
              benefit_type_code: "1",
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              date: task.appeal.decision_date.to_date,
              # Testing that the modifier is now 171 since 170 was taken
              end_product_modifier: "171",
              end_product_label: "ARC-Partial Grant",
              end_product_code: "170PGAMC",
              station_of_jurisdiction: "397",
              gulf_war_registry: false,
              suppress_acknowledgement_letter: true
            },
            veteran_hash: task.appeal.veteran.to_vbms_hash
          )
        end
      end
    end
  end
end

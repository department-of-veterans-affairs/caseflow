require "rails_helper"

RSpec.feature "Establish Claim - ARC Dispatch" do
  before do
    # Set the time zone to the current user's time zone for proper date conversion
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 1, 1))

    BGSService.end_product_data = []

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::AppealRepository).to receive(:update_vacols_after_dispatch!).and_call_original
  end

  let(:case_worker) do
    User.create(station_id: "123", css_id: "JANESMITH", full_name: "Jane Smith")
  end

  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
  end

  let(:appeal_full_grant) do
    Generators::Appeal.create(vacols_record: :full_grant_decided, documents: documents)
  end

  let(:appeal_partial_grant) do
    Generators::Appeal.create(vacols_record: :partial_grant_decided, documents: documents)
  end

  let(:documents) do
    [Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)]
  end

  let(:vacols_record) { :remand_decided }

  context "As a manager" do
    let!(:current_user) do
      User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"])
    end

    scenario "View quotas and update employee count" do
      # Create 4 incomplete tasks and one completed today
      4.times { Generators::EstablishClaim.create(aasm_state: :unassigned) }

      Generators::EstablishClaim.create(appeal_id: appeal.id, user: case_worker, aasm_state: :assigned).tap do |task|
        task.start!
        task.complete!(status: :routed_to_arc)
      end

      visit "/dispatch/work-assignments"
      expect(page).to have_content("ARC Work Assignments")

      # Validate help link
      find('#menu-trigger').click
      find_link("Help").click
      expect(page).to have_content("Caseflow Dispatch Help")
      page.driver.go_back

      fill_in "the number of people", with: "2"
      click_on "Update"
      expect(find_field("the number of people").value).to have_content("2")

      # Check user quotas and totals
      expect(page).to have_content("1. Jane Smith 0 0 1 1 3")
      expect(page).to have_content("2. Not logged in 0 0 0 0 2")
      expect(page).to have_content("Employee Total 0 0 1 1 5")

      # Two more users starting tasks should force the number of people to bump up to 3
      %w(June Jeffers).each do |name|
        Generators::EstablishClaim.create(
          user: Generators::User.create(full_name: "#{name} Smith"),
          aasm_state: :assigned,
          appeal_id: (name == "June" ? appeal_full_grant.id : appeal_partial_grant.id)
        ).tap do |task|
          task.start!
          task.complete!(status: :routed_to_arc)
        end
      end

      fill_in "the number of people", with: "3"
      click_on "Update"
      expect(find_field("the number of people").value).to have_content("3")

      # Validate remanders are handled correctly
      expect(page).to have_content("1. Jane Smith 0 0 1 1 3")
      expect(page).to have_content("2. June Smith 1 0 0 1 2")
      expect(page).to have_content("3. Jeffers Smith 0 1 0 1 2")
      expect(page).to have_content("Employee Total 1 1 1 3 7")
    end

    scenario "Edit individual user quotas" do
      4.times { Generators::EstablishClaim.create(aasm_state: :unassigned) }

      appeal_id = {
        "Janet" => appeal.id,
        "June" => appeal_full_grant.id,
        "Jeffers" => appeal_partial_grant.id
      }

      %w(Janet June Jeffers).each do |name|
        Generators::EstablishClaim.create(
          user: Generators::User.create(full_name: "#{name} Smith"),
          aasm_state: :assigned,
          appeal_id: appeal_id[name]
        ).tap do |task|
          task.start!
          task.complete!(status: :routed_to_arc)
        end
      end

      visit "/dispatch/work-assignments"
      expect(page).to have_content("1. Janet Smith 0 0 1 1 3")
      expect(page).to have_content("2. June Smith 1 0 0 1 2")
      expect(page).to have_content("3. Jeffers Smith 0 1 0 1 2")
      expect(page).to have_content("Employee Total 1 1 1 3 7")

      # Begin editing June's quota
      june_quota = UserQuota.where(user: User.where(full_name: "June Smith").first).first

      within("#table-row-1") do
        click_on "Edit"
        fill_in "quota-#{june_quota.id}", with: "5"
        click_on "Save"
      end

      expect(page).to have_content("1. Janet Smith 0 0 1 1 1")
      expect(page).to have_content("2. June Smith 1 0 0 1 5")
      expect(page).to have_content("3. Jeffers Smith 0 1 0 1 1")
      expect(page).to have_content("Employee Total  1 1 1 3 7")

      find("#button-unlock-quota-#{june_quota.id}").click

      expect(page).to have_content("1. Janet Smith 0 0 1 1 3")
      expect(page).to have_content("2. June Smith 1 0 0 1 2")
      expect(page).to have_content("3. Jeffers Smith 0 1 0 1 2")
    end

    scenario "Editing won't work if there's only one user" do
      4.times { Generators::EstablishClaim.create(aasm_state: :unassigned) }

      appeal_id = {
        "Janet" => appeal.id
      }

      %w(Janet).each do |name|
        Generators::EstablishClaim.create(
          user: Generators::User.create(full_name: "#{name} Smith"),
          aasm_state: :assigned,
          appeal_id: appeal_id[name]
        ).tap do |task|
          task.start!
          task.complete!(status: :routed_to_arc)
        end
      end

      visit "/dispatch/work-assignments"
      expect(page).to have_content("1. Janet Smith 0 0 1 1 5")

      # Begin editing Janet's quota
      janet_quota = UserQuota.where(user: User.where(full_name: "Janet Smith").first).first

      within("#table-row-0") do
        click_on "Edit"
        fill_in "quota-#{janet_quota.id}", with: "7"
        click_on "Save"
      end

      expect(page).to have_content("1. Janet Smith 0 0 1 1 5")

      within("#table-row-0") do
        click_on "Edit"
        fill_in "quota-#{janet_quota.id}", with: "3"
        click_on "Save"
      end

      expect(page).to have_content("1. Janet Smith 0 0 1 1 5")
    end

    scenario "View unprepared tasks page" do
      unprepared_task = Generators::EstablishClaim.create(aasm_state: :unprepared)

      visit "/dispatch/work-assignments"
      click_on "View Claims Missing Decisions"

      # should not see any tasks younger than 1 day
      page.within_window windows.last do
        expect(page).to be_titled("Claims Missing Decisions")
        expect(page).to have_content("Total missing: 0")
        page.driver.browser.close
      end

      unprepared_task.update!(created_at: Time.zone.now - 1.day)

      visit "/dispatch/work-assignments"
      click_on "View Claims Missing Decisions"

      # should see the unprepared task
      page.within_window windows.last do
        expect(page).to have_content("Claims Missing Decisions")
        expect(page).to have_content(unprepared_task.appeal.veteran_name)
        page.driver.browser.close
      end
    end

    scenario "View canceled EPs page" do
      reason = "Cuz it's canceled"

      Generators::EstablishClaim.create(
        user: Generators::User.create(full_name: "Cance L. Smith"),
        aasm_state: :assigned
      ).tap do |task|
        task.start!
        task.cancel!(reason)
      end

      visit "/dispatch/work-assignments"
      click_on "View Canceled Tasks"

      # should see the canceled tasks
      page.within_window windows.last do
        expect(page).to be_titled("Canceled EPs")
        expect(page).to have_content("Canceled EPs")
        expect(find(:xpath, "//tbody/tr[1]/td[5]").text).to eql(reason)
        page.driver.browser.close
      end
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

      expect(page).to have_content("There are claims ready to get picked up for today")

      # Validate completed task is in view history (along with the header, totaling 2 tr's)
      expect(page).to have_selector('#work-history-table tr', count: 2)
      expect(page).to have_content("(#{completed_task.appeal.sanitized_vbms_id})")
      expect(page).to have_content("Routed in VACOLS")

      # The oldest task (task local var) is now set to a higher security level so
      # it will be skipped for task_with_access
      click_on "Establish next claim"

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
      click_on "Establish next claim"

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

      click_on "Route claim"

      find_label_for("gulfWarRegistry").click
      expect(page).to have_content("Create End Product")

      page.go_back

      expect(page).to have_content("Review Decision")

      click_on "Route claim"

      expect(page).to have_content("Create End Product")

      # Validate that the state was saved from the earlier checkbox click
      expect(find("#gulfWarRegistry", visible: false)).to be_checked
    end

    scenario "Cannot re-complete a completed task" do
      task.assign!(:assigned, current_user)
      task.start!(:started)

      visit "/dispatch/establish-claim/#{task.id}"

      task.complete!(status: 0)

      click_on "Route claim"
      expect(page).to have_content("This task was already completed")
    end

    scenario "Cancel a claims establishment" do
      task.assign!(:assigned, current_user)

      # The cancel button is the same on both the review and form pages, so one test
      # can adequetly test both of them.
      visit "/dispatch/establish-claim/#{task.id}"
      find_label_for("riceCompliance").click
      click_on "Cancel"

      expect(page).to have_css(".cf-modal")

      # Validate I can't cancel without entering an explanation
      click_on "Stop processing claim"
      expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
      expect(page).to have_css(".cf-modal")
      expect(page).to have_content("Please enter an explanation")

      # Validate closing the cancellation modal
      click_on "Close"
      expect(page).to_not have_css(".cf-modal")

      # Open modal
      click_on "Cancel"
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
      allow(VBMSService).to receive(:establish_claim!).and_raise(ep_already_exists_error)

      task.assign!(:assigned, current_user)
      visit "/dispatch/establish-claim/#{task.id}"
      click_on "Route claim"

      expect(find_field("endProductModifier")[:value]).to eq("070")

      click_on "Create End Product"

      expect(page).to_not have_content("Success!")
      expect(page).to have_content("Unable to assign or create a new EP for this claim")
      expect(find_field("endProductModifier")[:value]).to eq("071")

      # Missing SSN error
      allow(VBMSService).to receive(:establish_claim!).and_raise(missing_ssn_error)

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
        click_on "Establish next claim"

        expect(page).to have_content("Multiple Decision Documents")

        # Text on the tab
        expect(page).to have_content("Decision 1 (")
        find("#main-tab-1").click

        expect(page).to have_content("Route claim for Decision 2")
        click_on "Route claim for Decision 2"

        expect(page).to have_content("Benefit Type")
      end

      scenario "the EP creation page has a link back to decision review" do
        visit "/dispatch/establish-claim"
        click_on "Establish next claim"

        expect(page).to have_content("Multiple Decision Documents")
        click_on "Route claim for Decision 1"
        click_on "< Back to Review Decision"
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

        click_on "Route claim"

        expect(find_field("Station of Jurisdiction").value).to eq("351 - Muskogee, OK")

        click_on "Create End Product"
        find_label_for("confirmNote").click
        click_on "Finish routing claim"

        expect(page).to have_content("Success!")
        expect(page).to have_content("Reviewed Full Grant decision")
        expect(page).to have_content("Established EP: 070BVAGR - BVA Grant (070) for Station 351 - Muskogee")

        expect(page).to have_content("There are no more claims in your queue")
        expect(page).to have_button("Establish next claim", disabled: true)

        expect(task.appeal.reload.dispatched_to_station).to eq("351")
        expect(task.reload.completion_status).to eq("routed_to_ro")
      end

      scenario "Establish a new claim with special issue routed to ROJ" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        find_label_for("riceCompliance").click
        click_on "Route claim"

        expect(find_field("Station of Jurisdiction").value).to eq("321 - New Orleans, LA")

        click_on "Create End Product"

        # Form Page
        expect(page).to have_content("Route Claim Add VBMS Note")
        expect(find_field("VBMS Note").value).to have_content("Rice Compliance")

        # Validate I cannot return to Review Decision from the VACOLS Update page
        expect(page).to_not have_content("< Back to Review Decision")
        page.driver.go_back
        expect(page).to have_content("Cannot edit end product")

        find_label_for("confirmNote").click
        click_on "Finish routing claim"

        # Confirmation Page
        expect(page).to have_content("Success!")
        expect(page).to have_content("Added VBMS Note on Rice Compliance")

        expect(task.reload.completion_status).to eq("routed_to_ro")
      end

      scenario "Establish a new claim with special issues by routing via email", focus: true do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        find_label_for("dicDeathOrAccruedBenefitsUnitedStates").click
        click_on "Route claim"

        # Validate the correct steps on the progress bar are activated
        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Decision")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Route Claim")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Confirmation")

        # Validate I can return to Review Decision from the VACOLS Update page
        click_on "< Back to Review Decision"
        click_on "Route claim"

        expect(page).to have_content("We are unable to create an EP for claims with this Special Issue")

        find_label_for("confirmEmail").click
        click_on "Finish routing claim"

        expect(page).to have_content("Sent email to: PMCAppeals.VBAMIW@va.gov, tammy.boggs@va.gov in " \
                                     "Milwaukee Pension Center, WI - re: DIC - death, or accrued benefits")

        expect(task.reload.completion_status).to eq("special_issue_emailed")
      end

      # :nocov:
      context "When there is an existing 070 EP",
              skip: "This test hangs somewhat regularly for unknown reasons" do
        before do
          BGSService.end_product_data = [
            {
              benefit_claim_id: "1",
              claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
              claim_type_code: "070BVAGRARC",
              end_product_type_code: "070",
              status_type_code: "PEND"
            }
          ]
        end

        skip "Assigning it to complete the claims establishment" do
          visit "/dispatch/establish-claim"
          click_on "Establish next claim"
          expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

          click_on "Route claim"
          expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
          click_on "Assign to Claim"

          expect(page).to have_content("Success!")

          expect(task.reload.outgoing_reference_id).to eq("1")
          expect(task.reload.completion_status).to eq("assigned_existing_ep")
        end
      end
    end

    # :nocov:

    context "For a partial grant" do
      let(:vacols_record) { :partial_grant_decided }

      # :nocov:
      scenario "Establish a new claim routed to ARC",
               skip: "This test is failing because of a stale element reference"do
        # Mock the claim_id returned by VBMS's create end product
        Fakes::VBMSService.end_product_claim_id = "CLAIM_ID_123"

        visit "/dispatch/establish-claim"
        # Decision Page
        click_on "Establish next claim"

        expect(page).to have_content("Review Decision")
        expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

        click_on "Route claim"

        expect(find(".cf-app-segment > h2")).to have_content("Create End Product")
        expect(find_field("Station of Jurisdiction").value).to eq "397 - ARC"

        # Test text, radio button, & checkbox inputs
        find_label_for("gulfWarRegistry").click
        click_on "Create End Product"

        # Confirmation Page
        expect(page).to have_content("Success!")
        expect(page).to have_content("Established EP: 070RMBVAGARC - ARC Remand with BVA Grant for Station 397 - ARC")
        expect(page).to have_content("VACOLS Updated: Changed Location to 98")
        expect(page).to_not have_content("Added VBMS Note")
        expect(page).to_not have_content("Added Diary Note")

        # Validate the correct steps on the progress bar are activated
        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Decision")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Route Claim")
        expect(page).to have_css(".cf-progress-bar-activated", text: "3. Confirmation")

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: task.appeal.decision_date.to_date,
            end_product_modifier: "070",
            end_product_label: "ARC Remand with BVA Grant",
            end_product_code: "070RMBVAGARC",
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
        expect(page).to have_content("Way to go! You have completed all the claims assigned to you.")
        expect(page).to have_css(".usa-button-disabled")
      end

      # :nocov:

      scenario "Establish a new claim with special issues" do
        visit "/dispatch/establish-claim"

        click_on "Establish next claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

        # Select special issues
        find_label_for("riceCompliance").click
        find_label_for("privateAttorneyOrAgent").click

        # Move on to note page
        click_on "Route claim"

        expect(page).to have_content("Create End Product")

        # Test that special issues were saved
        expect(task.appeal.reload.rice_compliance).to be_truthy
        click_on "Create End Product"

        expect(page).to have_content("Add the diary note")

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

        expect(find(".cf-app-segment > h1")).to have_content("Route Claim")
        find_label_for("confirmNote").click

        click_on "Finish routing claim"

        expect(page).to have_content("Success!")
        expect(page).to have_content("VACOLS Updated: Changed Location to 50")
        expect(page).to have_content("Added VBMS Note on Private Attorney or Agent; Rice Compliance")
        expect(page).to have_content("VACOLS Updated: Added Diary Note on Private Attorney or Agent; Rice Compliance")

        expect(task.appeal.reload.rice_compliance).to be_truthy
        expect(task.reload.completion_status).to eq("routed_to_ro")

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "313",
            date: task.appeal.decision_date.to_date,
            end_product_modifier: "070",
            end_product_label: "Remand with BVA Grant (070)",
            end_product_code: "070RMNDBVAG",
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
        click_on "Route claim"

        expect(page).to have_content("Route Claim Confirm VACOLS Update")

        # Validate special issue text within vacols note
        expect(page).to have_content("DIC - death, or accrued benefits")

        # Validate no VBMS-related content
        expect(page).to_not have_content("Update VACOLS and VBMS")

        # Validate I can return to Review Decision from the VACOLS Update page
        expect(page).to have_content("< Back to Review Decision")
        click_on "< Back to Review Decision"
        click_on "Route claim"

        # Valdiate correct vacols location
        expect(page).to have_content("50")

        click_on "Finish routing claim"

        expect(page).to have_content("Success!")
        expect(task.reload.completion_status).to eq("special_issue_vacols_routed")
      end

      context "When there is an existing 070 EP" do
        before do
          BGSService.end_product_data = [
            {
              benefit_claim_id: "2",
              claim_receive_date: 10.days.from_now.to_formatted_s(:short_date),
              claim_type_code: "070RMND",
              end_product_type_code: "070",
              status_type_code: "PEND"
            }
          ]
        end

        scenario "Establish a new claim defaults to creating a 071 EP" do
          visit "/dispatch/establish-claim"
          click_on "Establish next claim"
          click_on "Route claim"

          expect(page).to have_content("Existing EP")

          # Validate the Back link takes you back to the Review Decision page
          click_on "< Back to Review Decision"

          expect(page).to have_content("Review Decision")

          click_on "Route claim"
          click_on "Create new EP"
          click_on "Create End Product"

          expect(page).to have_content("Success!")

          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            claim_hash: {
              benefit_type_code: "1",
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              date: task.appeal.decision_date.to_date,
              # Testing that the modifier is now 071 since 070 was taken
              end_product_modifier: "071",
              end_product_label: "ARC Remand with BVA Grant",
              end_product_code: "070RMBVAGARC",
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

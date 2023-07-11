# frozen_string_literal: true

RSpec.feature "Establish Claim - ARC Dispatch", :all_dbs do
  before do
    Timecop.freeze(pre_ramp_start_date)

    Fakes::BGSService.inaccessible_appeal_vbms_ids ||= []
    Fakes::BGSService.inaccessible_appeal_vbms_ids << inaccessible_appeal.veteran_file_number

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(AppealRepository).to receive(:update_vacols_after_dispatch!).and_call_original
  end

  let(:case_worker) do
    create(:user, station_id: "123", css_id: "JANESMITH", full_name: "Jane Smith")
  end

  let(:case_full_grant) do
    create(:case_with_decision, :status_complete, bfregoff: "RO21", case_issues:
      [create(:case_issue, :education, :disposition_allowed)])
  end

  let(:appeal_full_grant) do
    create(:legacy_appeal, :with_veteran, vacols_case: case_full_grant)
  end

  let(:folder) { build(:folder, tioctime: 23.days.ago.midnight) }

  let(:case_remand) do
    create(:case_with_multi_decision, :status_remand, folder: folder)
  end

  let(:appeal_remand) do
    create(:legacy_appeal, :with_veteran, vacols_case: case_remand)
  end

  let(:case_partial_grant) do
    create(:case_with_decision, :status_remand, bfregoff: "RO21", case_issues:
        [create(:case_issue, :education, :disposition_allowed), create(:case_issue, :education, :disposition_remanded)])
  end

  let(:appeal_partial_grant) do
    create(:legacy_appeal, :with_veteran, vacols_case: case_partial_grant)
  end

  let(:invalid_case) do
    create(:case_with_decision, :status_complete, bfddec: nil, case_issues:
        [create(:case_issue, :education, :disposition_allowed)])
  end

  let(:invalid_appeal) do
    create(:legacy_appeal, vacols_case: invalid_case)
  end

  let(:inaccessible_case) do
    create(:case_with_decision, :status_complete, case_issues:
        [create(:case_issue, :education, :disposition_allowed)])
  end

  let(:inaccessible_appeal) do
    create(:legacy_appeal, vacols_case: inaccessible_case)
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
      4.times { create(:establish_claim, aasm_state: :unassigned, prepared_at: Date.yesterday) }

      create(:establish_claim, appeal: appeal_remand, user: case_worker, aasm_state: :assigned).tap do |task|
        task.start!
        task.complete!(status: :routed_to_arc)
      end

      visit "/dispatch/work-assignments"
      expect(page).to have_content("ARC Work Assignments")

      # Validate help link
      find("#menu-trigger").click
      find_link("Help").click
      expect(page).to have_content("Welcome to the Dispatch Help page!")
      page.driver.go_back

      fill_in "the number of people", with: "2"
      click_on "Update"
      expect(find_field("the number of people").value).to have_content("2")

      # Check user quotas and totals
      expect(page).to have_content("1.\nJane Smith\n0 0 1 1 3")
      expect(page).to have_content("2.\nNot logged in\n0 0 0 0 2")
      expect(page).to have_content("Employee Total 0 0 1 1 5")

      # Two more users starting tasks should force the number of people to bump up to 3
      %w[June Jeffers].each do |name|
        create(:establish_claim,
               appeal: ((name == "June") ? appeal_full_grant : appeal_partial_grant),
               user: create(:user, full_name: "#{name} Smith"),
               aasm_state: :assigned).tap do |task|
          task.start!
          task.complete!(status: :routed_to_arc)
        end
      end

      fill_in "the number of people", with: "3"
      click_on "Update"
      expect(find_field("the number of people").value).to have_content("3")

      # Validate remanders are handled correctly
      expect(page).to have_content("1.\nJane Smith\n0 0 1 1 3")
      expect(page).to have_content("2.\nJune Smith\n1 0 0 1 2")
      expect(page).to have_content("3.\nJeffers Smith\n0 1 0 1 2")
      expect(page).to have_content("Employee Total 1 1 1 3 7")
    end

    scenario "Edit individual user quotas" do
      4.times { create(:establish_claim, aasm_state: :unassigned, prepared_at: Date.yesterday) }

      appeals_by_name = {
        "Janet" => appeal_remand,
        "June" => appeal_full_grant,
        "Jeffers" => appeal_partial_grant
      }

      %w[Janet June Jeffers].each do |name|
        create(:establish_claim,
               appeal: appeals_by_name[name],
               user: create(:user, full_name: "#{name} Smith"),
               aasm_state: :assigned).tap do |task|
          task.start!
          task.complete!(status: :routed_to_arc)
        end
      end

      visit "/dispatch/work-assignments"
      expect(page).to have_content("1.\nJanet Smith\n0 0 1 1 3")
      expect(page).to have_content("2.\nJune Smith\n1 0 0 1 2")
      expect(page).to have_content("3.\nJeffers Smith\n0 1 0 1 2")
      expect(page).to have_content("Employee Total 1 1 1 3 7")

      # Begin editing June's quota
      june_quota = UserQuota.where(user: User.where(full_name: "June Smith").first).first

      within("#table-row-1") do
        click_on "Edit"
        fill_in "quota-#{june_quota.id}", with: "5"
        click_on "Save"
      end

      expect(page).to have_content("1.\nJanet Smith\n0 0 1 1 1")
      expect(page).to have_content("2.\nJune Smith\n1 0 0 1 5")
      expect(page).to have_content("3.\nJeffers Smith\n0 1 0 1 1")
      expect(page).to have_content("Employee Total 1 1 1 3 7")

      find("#button-unlock-quota-#{june_quota.id}").click

      expect(page).to have_content("1.\nJanet Smith\n0 0 1 1 3")
      expect(page).to have_content("2.\nJune Smith\n1 0 0 1 2")
      expect(page).to have_content("3.\nJeffers Smith\n0 1 0 1 2")
    end

    scenario "Editing won't work if there's only one user" do
      4.times { create(:establish_claim, aasm_state: :unassigned, prepared_at: Date.yesterday) }

      appeals_by_name = {
        "Janet" => appeal_remand
      }

      %w[Janet].each do |name|
        create(:establish_claim,
               appeal: appeals_by_name[name],
               user: create(:user, full_name: "#{name} Smith"),
               aasm_state: :assigned).tap do |task|
          task.start!
          task.complete!(status: :routed_to_arc)
        end
      end

      visit "/dispatch/work-assignments"
      expect(page).to have_content("1.\nJanet Smith\n0 0 1 1 5")

      # Begin editing Janet's quota
      janet_quota = UserQuota.where(user: User.where(full_name: "Janet Smith").first).first

      within("#table-row-0") do
        click_on "Edit"
        fill_in "quota-#{janet_quota.id}", with: "7"
        click_on "Save"
      end

      expect(page).to have_content("1.\nJanet Smith\n0 0 1 1 5")

      within("#table-row-0") do
        click_on "Edit"
        fill_in "quota-#{janet_quota.id}", with: "3"
        click_on "Save"
      end

      expect(page).to have_content("1.\nJanet Smith\n0 0 1 1 5")
    end

    scenario "View unprepared tasks page" do
      unprepared_task = create(:establish_claim, aasm_state: :unprepared)

      visit "/dispatch/work-assignments"
      click_on "View claims missing decisions"

      # should not see any tasks younger than 1 day
      page.within_window windows.last do
        expect(page).to be_titled("Claims Missing Decisions")
        expect(page).to have_content("Total missing: 0")
        page.driver.browser.close
      end

      unprepared_task.update!(created_at: Time.zone.now - 1.day)

      visit "/dispatch/work-assignments"
      click_on "View claims missing decisions"

      # should see the unprepared task
      page.within_window windows.last do
        expect(page).to have_content("Claims Missing Decisions")
        expect(page).to have_content(unprepared_task.appeal.veteran_name)
        expect(page).to have_content(unprepared_task.appeal.outcoded_by_name)
        page.driver.browser.close
      end
    end

    scenario "View canceled EPs page" do
      reason = "Cuz it's canceled"

      create(:establish_claim,
             user: create(:user, full_name: "Cance L. Smith"),
             aasm_state: :assigned).tap do |task|
        task.start!
        task.cancel!(reason)
      end

      visit "/dispatch/work-assignments"
      click_on "View canceled tasks"

      # should see the canceled tasks
      page.within_window windows.last do
        expect(page).to be_titled("Canceled EPs")
        expect(page).to have_content("Canceled EPs")
        expect(find(:xpath, "//tbody/tr[1]/td[5]").text).to eql(reason)
        page.driver.browser.close
      end
    end

    scenario "View oldest unassigned tasks page" do
      2.times { create(:establish_claim, aasm_state: :unassigned, prepared_at: Date.yesterday) }

      visit "/dispatch/admin"
      expect(page).to have_content("Oldest Unassigned Tasks")
      # Expect 3 table rows, the header and 2 tasks
      expect(page).to have_selector("tr", count: 3)
    end
  end

  context "As a caseworker" do
    let!(:current_user) { User.authenticate!(roles: ["Establish Claim"]) }

    let!(:task) do
      create(:establish_claim,
             created_at: 3.days.ago,
             prepared_at: Date.yesterday,
             appeal: appeal_remand,
             aasm_state: "unassigned")
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

    let(:client_error) { VBMS::ClientError }

    scenario "Assign the correct new task to myself" do
      # Create an older task with an inaccessible appeal
      Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        prepared_at: Date.yesterday,
        aasm_state: :unassigned,
        appeal: inaccessible_appeal
      )

      # Create a task already assigned to another user
      Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        prepared_at: Date.yesterday,
        user_id: case_worker.id,
        aasm_state: :started
      )

      # Create a task already completed by me
      completed_task = Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        prepared_at: Date.yesterday,
        user_id: current_user.id,
        aasm_state: :completed,
        completion_status: :special_issue_vacols_routed
      )

      # Create an invalid task, this should be invalidated and skipped
      invalid_task = Generators::EstablishClaim.create(
        created_at: 4.days.ago,
        prepared_at: Date.yesterday,
        aasm_state: :unassigned,
        appeal: invalid_appeal
      )

      visit "/dispatch/establish-claim"

      expect(page).to have_content("There are claims ready to get picked up for today")

      # Validate completed task is in view history (along with the header, totaling 2 tr's)
      expect(page).to have_selector("#work-history-table tr", count: 2)
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
      expect(task.claim_establishment.outcoding_date).to eq(appeal_remand.outcoding_date)
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

      click_label("gulfWarRegistry")
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
      click_label("riceCompliance")
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
      expect(task.appeal.dispatch_tasks.where(type: :EstablishClaim).to_complete.count).to eq(0)
      expect(task.comment).to eq("Test")

      # Validate special issue isn't saved on cancel
      expect(task.appeal.reload.rice_compliance).to be_falsey
    end

    scenario "Cancel a claim after it has already been completed" do
      task.assign!(:assigned, current_user)
      task.start!(:started)
      visit "/dispatch/establish-claim/#{task.id}"
      task.complete!(status: 0)

      click_on "Cancel"
      page.fill_in "Explanation", with: "Test"
      click_on "Stop processing claim"

      expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
      expect(page).to have_content("This task was already completed")
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

      # Client error
      allow(VBMSService).to receive(:establish_claim!).and_raise(client_error)
      allow_any_instance_of(ApplicationController).to receive(:error_uuid).and_return(1234)
      expect(Raven).to receive(:capture_exception).with(client_error, hash_including(extra: { error_uuid: 1234 }))
      click_on "Create End Product"
      expect(page).to_not have_content("Success!")
      expect(page).to have_content("System Error")
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

        expect(find("#review-decision-heading")).to have_content("Multiple Decision Documents")

        # Text on the tab
        expect(page).to have_content("Decision 1 (")
        safe_click("#main-tab-1")

        safe_click("#button-Route-claim-for-Decision-2")

        expect(page).to have_content("Benefit Type")
      end

      scenario "the EP creation page has a link back to decision review" do
        visit "/dispatch/establish-claim"
        click_on "Establish next claim"

        expect(find("#review-decision-heading")).to have_content("Multiple Decision Documents")
        click_on "Route claim for Decision 1"
        click_on "< Back to Review Decision"
        expect(page).to have_content("Multiple Decision Documents")
      end
    end

    context "For a full grant" do
      let!(:task) do
        create(:establish_claim,
               created_at: 3.days.ago,
               prepared_at: Date.yesterday,
               appeal: appeal_full_grant,
               aasm_state: "unassigned")
      end

      scenario "Establish a new claim with special issue routed to national office" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        click_label("mustardGas")

        # Validate it routes correctly even if an unsupported special issue is checked
        click_label("dicDeathOrAccruedBenefitsUnitedStates")

        click_on "Route claim"

        expect(find_field("Station of Jurisdiction").value).to eq("351 - Muskogee, OK")

        click_on "Create End Product"
        click_label("confirmNote")
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
        click_label("riceCompliance")
        click_on "Route claim"

        expect(find_field("Station of Jurisdiction").value).to eq("321 - New Orleans, LA")

        click_on "Create End Product"

        # Form Page
        expect(page).to have_content("Route Claim\nAdd VBMS Note")
        expect(find_field("VBMS Note").value).to have_content("Rice Compliance")

        # Validate I cannot return to Review Decision from the VACOLS Update page
        expect(page).to_not have_content("< Back to Review Decision")
        page.driver.go_back
        expect(page).to have_content("Cannot edit end product")

        click_label("confirmNote")
        click_on "Finish routing claim"

        # Confirmation Page
        expect(page).to have_content("Success!")
        expect(page).to have_content("Added VBMS Note on Rice Compliance")

        expect(task.reload.completion_status).to eq("routed_to_ro")
      end

      scenario "Establish a new claim with special issues by routing via email" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        click_label("dicDeathOrAccruedBenefitsUnitedStates")
        click_on "Route claim"

        # Validate the correct steps on the progress bar are activated
        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Decision")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Route Claim")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Confirmation")

        # Validate I can return to Review Decision from the VACOLS Update page
        click_on "< Back to Review Decision"
        click_on "Route claim"

        expect(page).to have_content("We are unable to create an EP for claims with this Special Issue")

        click_label("confirmEmail")
        click_on "Finish routing claim"

        expect(page).to have_content("Sent email to: PMCAppeals.VBAMIW@va.gov, tammy.boggs@va.gov in " \
                                     "Milwaukee Pension Center, WI - re: DIC - death, or accrued benefits")

        expect(task.reload.completion_status).to eq("special_issue_emailed")
      end

      context "When there is an existing 070 EP" do
        let!(:end_product) do
          Generators::EndProduct.build(
            bgs_attrs: {
              claim_type_code: "070BVAGRARC",
              end_product_type_code: "070",
              status_type_code: "PEND"
            }
          )
        end
        # nocov
        scenario "Assigning it to complete the claims establishment", skip: "flakey hang" do
          visit "/dispatch/establish-claim"
          click_on "Estsablish next claim"
          # expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

          click_on "Route claim"
          # expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")
          expect(page).to have_content("Route Claim")
          expect(page).to have_selector(:link_or_button, "Assign to Claim")
          click_on "Assign to Claim" # unknown reason sometimes hangs here

          expect(page).to have_content("Success!")

          expect(task.reload.outgoing_reference_id).to eq(end_product.claim_id)
          expect(task.reload.completion_status).to eq("assigned_existing_ep")
        end
        # nocov
      end
    end

    context "For a partial grant" do
      let!(:task) do
        create(:establish_claim,
               created_at: 3.days.ago,
               prepared_at: Date.yesterday,
               appeal: appeal_partial_grant,
               aasm_state: "unassigned")
      end

      scenario "Establish a new claim routed to ARC", :aggregate_failure do
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
        click_label("gulfWarRegistry")
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
            suppress_acknowledgement_letter: true,
            claimant_participant_id: nil,
            limited_poa_code: nil,
            limited_poa_access: nil,
            status_type_code: nil
          },
          veteran_hash: task.appeal.veteran.to_vbms_hash,
          user: RequestStore[:current_user]
        )

        expect(AppealRepository).to have_received(:update_vacols_after_dispatch!)

        expect(task.reload.completed?).to be_truthy
        expect(task.completion_status).to eq("routed_to_arc")
        expect(task.outgoing_reference_id).to eq("CLAIM_ID_123")

        expect(task.appeal.reload.dispatched_to_station).to eq("397")

        # click_on "Caseflow Dispatch"
        expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

        # No tasks left
        expect(page).to have_content("Way to go!")
        expect(page).to have_content("You have completed all of the total cases assigned to you today")
        expect(page).to have_css(".usa-button-disabled")
      end

      scenario "Establish a new claim with special issues" do
        visit "/dispatch/establish-claim"

        click_on "Establish next claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{task.id}")

        # Select special issues
        click_label("riceCompliance")

        # Move on to note page
        safe_click "#button-Route-claim"

        expect(page).to have_content("Create End Product")

        # Test that special issues were saved
        expect(task.appeal.reload.rice_compliance).to be_truthy
        safe_click "#button-Create-End-Product"

        expect(page).to have_content("Add the diary note")

        # Validate we cannot go back
        expect(page).to_not have_content("< Back to Review Decision")
        page.driver.go_back
        expect(page).to have_content("Cannot edit end product")

        # Make sure note page contains the special issues
        expect(find_field("VBMS Note").value).to have_content("Rice Compliance")

        # Validate special issue text within vacols note
        expect(page).to have_content("Rice Compliance")

        # Validate note page shows correct decision type for claim in vbms note
        expect(find_field("VBMS Note").value).to have_content("The BVA Partial Grant decision")

        # Validate note page shows correct decision type for claim in vacols diary note
        expect(page).to have_content("Add the diary note: The BVA Partial Grant decision")

        # Validate correct vacols location
        expect(page).to have_content("50")

        # Ensure that the user stays on the note page on a refresh
        visit "/dispatch/establish-claim/#{task.id}"

        expect(find(".cf-app-segment > h1")).to have_content("Route Claim")
        click_label("confirmNote")

        safe_click "#button-Finish-routing-claim"

        expect(page).to have_content("Success!")
        expect(page).to have_content("VACOLS Updated: Changed Location to 50")
        expect(page).to have_content("Added VBMS Note on Rice Compliance")
        expect(page).to have_content("VACOLS Updated: Added Diary Note on Rice Compliance")

        expect(task.appeal.reload.rice_compliance).to be_truthy
        expect(task.reload.completion_status).to eq("routed_to_ro")

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "321",
            date: task.appeal.decision_date.to_date,
            end_product_modifier: "070",
            end_product_label: "Remand with BVA Grant (070)",
            end_product_code: "070RMNDBVAG",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: true,
            claimant_participant_id: nil,
            limited_poa_code: nil,
            limited_poa_access: nil,
            status_type_code: nil
          },
          veteran_hash: task.appeal.veteran.to_vbms_hash,
          user: RequestStore[:current_user]
        )
      end

      scenario "Establish a new claim with special issues with no EP" do
        task.assign!(:assigned, current_user)

        visit "/dispatch/establish-claim/#{task.id}"
        click_label("dicDeathOrAccruedBenefitsUnitedStates")
        click_on "Route claim"

        expect(page).to have_content("Route Claim\nConfirm VACOLS Update")

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
        let!(:end_product) do
          Generators::EndProduct.build(
            bgs_attrs: {
              claim_type_code: "070RMND",
              end_product_type_code: "070",
              status_type_code: "PEND"
            }
          )
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
              suppress_acknowledgement_letter: true,
              claimant_participant_id: nil,
              limited_poa_code: nil,
              limited_poa_access: nil,
              status_type_code: nil
            },
            veteran_hash: task.appeal.veteran.to_vbms_hash,
            user: RequestStore[:current_user]
          )
        end
      end
    end
  end

  context "As another employee" do
    let!(:current_user) do
      User.authenticate!(roles: ["Some non-Dispatch role"])
    end

    scenario "Attempts to view establish claim pages" do
      visit "/dispatch/establish-claim"
      expect(page).to have_content("You aren't authorized")
    end
  end
end

require "rails_helper"

RSpec.feature "Dispatch" do
  before do
    @vbms_id = "VBMS_ID1"

    BGSService.end_product_data = [
      {
        claim_receive_date: Time.zone.now - 20.days,
        claim_type_code: "172GRANT",
        status_type_code: "PEND"
      },
      {
        claim_receive_date: Time.zone.now + 10.days,
        claim_type_code: "170RMD",
        status_type_code: "CLR"
      },
      {
        claim_receive_date: Time.zone.now,
        claim_type_code: "172BVAG",
        status_type_code: "CAN"
      },
      {
        claim_receive_date: Time.zone.now - 200.days,
        claim_type_code: "172BVAG",
        status_type_code: "CLR"
      }]

    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided,
      @vbms_id => { documents: [Document.new(
        received_at: Time.current - 7.days, type: "BVA Decision",
        document_id: "123"
      )]
      }
    }
    appeal = Appeal.create(
      vacols_id: "123C",
      vbms_id: @vbms_id
    )
    @task = EstablishClaim.create(appeal: appeal)
  end

  context "As a manager" do
    before do
      User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"])
      @task.assign!(User.create(station_id: "123", css_id: "ABC"))

      create_tasks(20, initial_state: :completed)
    end

    scenario "View landing page" do
      visit "/dispatch/establish-claim"

      # Complete another task while the page is loaded. Verify we do not have it
      # added on "Show More" click
      create_tasks(1, initial_stae: :completed, id_prefix: "ZZZ")

      expect(page).to have_content(@vbms_id)
      expect(page).to have_content("Jane Smith", count: 10)
      expect(page).to have_content("Complete")
      click_on "Show More"

      expect(page).to_not have_content("Show More")

      # Verify we got a whole 10 more completed tasks
      expect(page).to have_content("Jane Smith", count: 20)
    end
  end

  context "As a caseworker" do
    before do
      User.authenticate!(roles: ["Establish Claim"])

      # completed by user task
      appeal = Appeal.create(vacols_id: "456D")
      @completed_task = EstablishClaim.create(appeal: appeal,
                                              user: current_user,
                                              assigned_at: 1.day.ago,
                                              started_at: 1.day.ago,
                                              completed_at: Time.zone.now.utc)

      other_user = User.create(css_id: "some", station_id: "stuff")
      @other_task = EstablishClaim.create(appeal: Appeal.new(vacols_id: "asdf"),
                                          user: other_user,
                                          assigned_at: 1.day.ago)

      allow(Appeal.repository).to receive(:establish_claim!)
    end

    context "Skip the associate EP page" do
      before do
        BGSService.end_product_data = []
      end

      scenario "Establish a new claim page and process" do
        visit "/dispatch/establish-claim"

        # View history
        expect(page).to have_content("Establish Next Claim")
        expect(page).to have_css("tr#task-#{@completed_task.id}")

        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

        # Can't start new task til current task is complete
        visit "/dispatch/establish-claim"
        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

        expect(page).to have_content("Review Decision")
        expect(@task.reload.user).to eq(current_user)
        expect(@task.started?).to be_truthy

        page.select "Full Grant", from: "decisionType"

        click_on "Create End Product"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(find(".cf-app-segment > h1")).to have_content("Create End Product")
        page.fill_in "Decision Date", with: "1"
        click_on "Create End Product"

        expect(page).to have_content("The date must be in mm/dd/yyyy format.")

        page.fill_in "Decision Date", with: "01/01/2017"
        click_on "Create End Product"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Congratulations!")
        expect(Appeal.repository).to have_received(:establish_claim!).with(
          claim: {
            "claim_type" => "Claim",
            "modifier" => "170",
            "poa" => "None",
            "claim_label" => "172BVAG - BVA Grant",
            "poa_code" => "",
            "gulf_war" => false,
            "allow_poa" => false,
            "suppress_acknowledgement" => false
          },
          appeal: @task.appeal
        )
        expect(@task.reload.complete?).to be_truthy
        expect(@task.completion_status).to eq(0)

        click_on "Caseflow Dispatch"
        expect(page).to have_current_path("/dispatch/establish-claim")

        # No tasks left
        expect(page).to have_content("No claims to establish right now")
        expect(page).to have_css(".usa-button-disabled")
      end

      scenario "Establish Claim form saves state when toggling decision" do
        @task.assign!(current_user)
        visit "/dispatch/establish-claim/#{@task.id}"
        click_on "Create End Product"
        expect(page).to have_content("Benefit Type") # React works
        expect(page).to_not have_content("POA Code")

        select("172", from: "Modifier")

        click_on "\u00ABBack to review"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Review Decision")

        click_on "Create End Product"

        expect(find_field("Modifier").value).to eq("172")
      end
    end

    scenario "Associate existing claim with decision" do
      visit "/dispatch/establish-claim"
      click_on "Establish Next Claim"
      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

      click_on "Create End Product"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_content("Existing EP")
    end

    scenario "Visit an Establish Claim task that is assigned to another user" do
      visit "/dispatch/establish-claim/#{@other_task.id}"
      expect(page).to have_current_path("/unauthorized")
    end

    # The cancel button is the same on both the review and form pages, so one test
    # can adequetly test both of them.
    scenario "Cancel an Establish Claim task returns me to landing page" do
      @task.assign!(current_user)
      visit "/dispatch/establish-claim/#{@task.id}"

      # Open modal
      click_on "Cancel"
      expect(page).to have_css(".cf-modal")

      # Try to cancel without explanation
      click_on "Cancel EP Establishment"
      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_css(".cf-modal")
      expect(page).to have_content("Please enter an explanation")

      # Close modal
      click_on "\u00AB Go Back"
      expect(page).to_not have_css(".cf-modal")

      # Open modal
      click_on "Cancel"
      expect(page).to have_css(".cf-modal")

      # Fill in explanation and cancel
      page.fill_in "Cancel Explanation", with: "Test"
      click_on "Cancel EP Establishment"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_content("EP Establishment Canceled")
      expect(@task.reload.complete?).to be_truthy
      expect(@task.appeal.tasks.where(type: :EstablishClaim).to_complete.count).to eq(0)
      expect(@task.comment).to eq("Test")
    end
  end
end

require "rails_helper"

RSpec.feature "Dispatch" do
  before do
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
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided,
      @vbms_id => { documents: [Document.new(
        received_at: (Time.current - 7.days).to_date, type: "BVA Decision",
        document_id: "123"
      )]
      }
    }
    Fakes::AppealRepository.end_product_claim_id = "CLAIM_ID_123"

    appeal = Appeal.create(
      vacols_id: "123C",
      vbms_id: @vbms_id
    )
    @task = EstablishClaim.create(appeal: appeal)

    Timecop.freeze(Time.utc(2017, 1, 1))

    allow(Fakes::AppealRepository).to receive(:establish_claim!).and_call_original
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
    end

    context "Skip the associate EP page" do
      before do
        BGSService.end_product_data = []
      end

      scenario "Establish a new claim page and process pt1" do
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
      end

      scenario "Establish a new claim page and process pt2" do
        visit "/dispatch/establish-claim"
        click_on "Establish Next Claim"
        page.select "Full Grant", from: "decisionType"
        click_on "Create End Product"

        # Test date, text, radio button, & checkbox inputs
        date = "01/08/2017"
        page.fill_in "Decision Date", with: date
        page.find("#gulfWarRegistry").trigger("click")
        click_on "Create End Product"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Congratulations!")
        expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
          claim: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: Date.strptime(date, "%m/%d/%Y"),
            end_product_modifier: "172",
            end_product_label: "BVA Grant",
            end_product_code: "172BVAG",
            gulf_war_registry: true,
            suppress_acknowledgement_letter: false
          },
          appeal: @task.appeal
        )
        expect(@task.reload.complete?).to be_truthy
        expect(@task.completion_status).to eq(0)
        expect(@task.outgoing_reference_id).to eq("CLAIM_ID_123")

        click_on "Caseflow Dispatch"
        expect(page).to have_current_path("/dispatch/establish-claim")

        # No tasks left
        expect(page).to have_content("No claims to establish right now")
        expect(page).to have_css(".usa-button-disabled")
      end

      skip "Establish Claim form saves state when going back/forward in browser" do
        @task.assign!(current_user)
        visit "/dispatch/establish-claim/#{@task.id}"
        click_on "Create End Product"
        expect(page).to have_content("Benefit Type") # React works

        page.fill_in "Decision Date", with: "01/01/1111"

        # page.go_back_in_browser (pseudocode)

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Review Decision")

        click_on "Create End Product"

        expect(find_field("Decision Date").value).to eq("01/01/1111")
      end

      context "Multiple decisions in VBMS" do
        before do
          Fakes::AppealRepository.records = {
            "123C" => Fakes::AppealRepository.appeal_remand_decided,
            "456D" => Fakes::AppealRepository.appeal_remand_decided,
            @vbms_id => { documents: [Document.new(
              received_at: (Time.current - 7.days).to_date, type: "BVA Decision",
              document_id: "123"
            ), Document.new(
              received_at: (Time.current - 6.days).to_date, type: "BVA Decision",
              document_id: "456"
            )
            ] }
          }
        end

        scenario "review page lets users choose which to use" do
          visit "/dispatch/establish-claim"
          click_on "Establish Next Claim"

          # View history
          expect(page).to have_content("Multiple Decision Documents")
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

      scenario "Unavailable modifiers" do
        # Test that the full grant associate page disables the Create New EP button
        visit "/dispatch/establish-claim"
        click_on "Establish Next Claim"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

        page.select("Full Grant", from: "decisionType")

        click_on "Create End Product"
        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("EP & Claim Label Modifiers in use")

        expect(page.find("#button-Create-New-EP")[:class]).to include("usa-button-disabled")

        # Test that for a partial grant, the list of available modifiers is restricted
        # to unused modifiers.
        visit "/dispatch/establish-claim"
        click_on "Establish Next Claim"
        page.select("Partial Grant", from: "decisionType")
        click_on "Create End Product"

        click_on "Create New EP"

        date = "01/08/2017"
        page.fill_in "Decision Date", with: date

        click_on "Create End Product"

        expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
        expect(page).to have_content("Congratulations!")

        expect(Fakes::AppealRepository).to have_received(:establish_claim!).with(
          claim: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            date: Date.strptime(date, "%m/%d/%Y"),
            end_product_modifier: "171",
            end_product_label: "AMC-Partial Grant",
            end_product_code: "170PGAMC",
            station_of_jurisdiction: "397",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          appeal: @task.appeal
        )
      end
    end

    scenario "Associate existing claim with decision" do
      visit "/dispatch/establish-claim"
      click_on "Establish Next Claim"
      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")

      click_on "Create End Product"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}")
      expect(page).to have_content("Existing EP")

      page.find("#button-Assign-to-Claim1").click

      expect(page).to have_content("Congratulations!")

      expect(@task.reload.completion_status)
        .to eq(Task.completion_status_code(:assigned_existing_ep))
      expect(@task.reload.outgoing_reference_id).to eq("1")
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

    scenario "A regional office special issue routes correctly" do
      @task.assign!(current_user)
      visit "/dispatch/establish-claim/#{@task.id}"
      page.find("#privateAttorney").trigger("click")
      click_on "Create End Product"
      click_on "Create New EP"
      expect(find_field("Station of Jurisdiction").value).to eq("")
    end

    scenario "A national office special issue routes correctly" do
      @task.assign!(current_user)
      visit "/dispatch/establish-claim/#{@task.id}"
      page.select "Remand", from: "decisionType"
      page.find("#mustardGas").trigger("click")
      click_on "Create End Product"
      click_on "Create New EP"
      expect(find_field("Station of Jurisdiction").value).to eq("351 - Muskogee")
    end

    scenario "A special issue is chosen and saved in database" do
      @task.assign!(current_user)
      visit "/dispatch/establish-claim/#{@task.id}"
      page.select "Remand", from: "decisionType"
      page.find("#insurance").trigger("click")
      click_on "Create End Product"
      click_on "Create New EP"
      click_on "Create End Product"
      expect(page).to have_content("Congratulations!")
      expect(@task.appeal.reload.insurance).to be_truthy
    end
  end
end

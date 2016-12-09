RSpec.feature "Dispatch" do
  before do
    reset_application!
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided
    }
    @vbms_id = "VBMS_ID1"
    appeal = Appeal.create(vacols_id: "123C", vbms_id: @vbms_id)
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
      expect(page).to have_content("ABC-19")
      expect(page).to have_content("Complete")
      expect(page).to_not have_content("ABC-9")
      click_on "Show More"

      expect(page).to_not have_content("Show More")
      expect(page).to have_content("ABC-9")

      # Verify we got a whole 10 more completed tasks
      expect(page).to have_content("ABC-0")
      expect(page).to_not have_content("ZZZ-0")
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
                                              completed_at: Time.now.utc)

      other_user = User.create(css_id: "some", station_id: "stuff")
      @other_task = EstablishClaim.create(appeal: Appeal.new(vacols_id: "asdf"),
                                          user: other_user,
                                          assigned_at: 1.day.ago)

      allow(Appeal.repository).to receive(:establish_claim!)
    end

    scenario "View my history of completed tasks" do
      visit "/dispatch/establish-claim"

      expect(page).to have_content(@completed_task.start_text)
      expect(page).to have_css("tr#task-#{@completed_task.id}")
    end

    scenario "Establish a new claim" do
      visit "/dispatch/establish-claim"
      click_on @task.start_text

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}/review")
      expect(page).to have_content("Review Decision")
      expect(@task.reload.user).to eq(current_user)
      expect(@task.started?).to be_truthy
      click_on "Create End Product"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}/new")
      expect(find(".cf-app-segment > h1")).to have_content("Create End Product")
      click_on "Create End Product"

      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}/complete")
      expect(Appeal.repository).to have_received(:establish_claim!).with(
        claim: {
          "claim_type" => "Claim",
          "modifier" => "170",
          "poa" => "None",
          "claim_label" => " ",
          "poa_code" => "",
          "gulf_war" => false,
          "allow_poa" => false,
          "suppress_acknowledgement" => false
        },
        appeal: @task.appeal
      )
      expect(@task.reload.complete?).to be_truthy
      expect(@task.completion_status).to eq(0)
    end

    scenario "Visit an Establish Claim task that is assigned to another user" do
      visit "/dispatch/establish-claim/#{@other_task.id}/review"
      expect(page).to have_current_path("/unauthorized")
    end

    scenario "Cancel an Establish Claim task returns me to landing page" do
      @task.assign!(current_user)
      visit "/dispatch/establish-claim/#{@task.id}/new"
      expect(page).to have_content("Create End Product") # React works

      click_on "Cancel"
      expect(page).to have_current_path("/dispatch/establish-claim")
      expect(@task.reload.complete?).to be_truthy
      expect(@task.appeal.tasks.where(type: :EstablishClaim).to_complete.count).to eq(1)
    end

    scenario "Return to decision on an Establish Claim task returns me decision review" do
      @task.assign!(current_user)
      visit "/dispatch/establish-claim/#{@task.id}/new"
      expect(page).to have_content("Create End Product") # React works

      click_on "\u00ABBack to review"
      expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}/review")
    end
  end
end

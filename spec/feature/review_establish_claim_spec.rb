RSpec.feature "Dispatch review" do
  before do
    reset_application!

    User.authenticate!(roles: ["Establish Claim"])

    @vbms_id = "VBMS_ID1"
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided,
      @vbms_id => { documents: [Document.new(
        received_at: Time.current - 7.days, type: "BVA Decision",
        document_id: "123"
      )]
      }
    }

    appeal = Appeal.create(vacols_id: "123C", vbms_id: @vbms_id)
    @task = EstablishClaim.create(appeal: appeal)
    @task.assign!(current_user)
  end

  scenario "clicking \"Create End Product\" moves to the form page" do
    visit "/dispatch/establish-claim/#{@task.id}/review"
    click_on "Create End Product"
    expect(page).to have_current_path("/dispatch/establish-claim/#{@task.id}/new")
    expect(page).to have_content("Create End Product")
  end

  scenario "clicking \"Cancel\" returns to the assign" do
    visit "/dispatch/establish-claim/#{@task.id}/review"
    click_on "Cancel"
    expect(page).to have_current_path("/dispatch/establish-claim")
    expect(@task.reload.completed_at).not_to be_nil
  end
end

RSpec.feature "Dispatch review" do
  before do
    reset_application!

    User.authenticate!(roles: ["Establish Claim"])

    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided
    }
    @vbms_id = "VBMS_ID1"
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
end

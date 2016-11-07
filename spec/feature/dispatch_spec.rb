RSpec.feature "Dispatch" do
  before do
    reset_application!
    User.authenticate!(roles: ["dispatch"])
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided
    }

    appeal = Appeal.create(vacols_id: "123C")
    CreateEndProduct.create(appeal: appeal)
  end

  scenario "Case Worker" do
    visit "/dispatch"

    expect(page).to have_content("Create End Product")
  end
end

RSpec.feature "Dispatch" do
  before do
    reset_application!
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided
    }

    appeal = Appeal.create(vacols_id: "123C")
    CreateEndProduct.create(appeal: appeal)
  end

  context "manager" do
    before do
      User.authenticate!(roles: ["dispatch", "manage dispatch"])
    end

    scenario "Case Worker" do
      visit "/dispatch"

      expect(page).to have_content("Work Flow")
    end
  end
end

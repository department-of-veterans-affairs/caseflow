RSpec.feature "Dispatch" do
  before do
    reset_application!
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided
    }
    @vbms_id = "VBMS_ID1"
    appeal = Appeal.create(vacols_id: "123C", vbms_id: @vbms_id)
    @end_product = CreateEndProduct.create(appeal: appeal)
  end

  context "manager" do
    before do
      User.authenticate!(roles: ["dispatch", "manage dispatch"])
    end
    context "task to complete" do
      scenario "Case Worker" do
        visit "/dispatch"

        expect(page).to have_content(@vbms_id)
        expect(page).to have_content("Unassigned")
      end
    end

    context "task completed" do
      before do
        @end_product.assign(User.create(station_id: "123", css_id: "ABC"))
        @end_product.update(started_at: Time.now.utc, completed_at: Time.now.utc)
      end

      scenario "Case Worker" do
        visit "/dispatch"

        expect(page).to have_content(@vbms_id)
        expect(page).to have_content("Complete")
      end
    end
  end

  context "employee" do
    context "task to complete" do
      before do
        User.authenticate!(roles: ["dispatch"])

        # completed by user task
        appeal = Appeal.create(vacols_id: "456D")
        @completed_task = CreateEndProduct.create(appeal: appeal,
                                                  user: current_user,
                                                  assigned_at: 1.day.ago,
                                                  started_at: 1.day.ago,
                                                  completed_at: Time.now.utc)
      end

      scenario "Case Worker" do
        visit "/dispatch"

        expect(page).to have_content("Create End Product")
        expect(page).to have_css("tr#task-#{@completed_task.id}")
      end
    end
  end
end

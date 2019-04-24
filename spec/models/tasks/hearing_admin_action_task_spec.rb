# frozen_string_literal: true

describe HearingAdminActionTask do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }

  describe "VerifyAddressTask after update" do
    let!(:verify_address_task) do
      HearingAdminActionVerifyAddressTask.create!(
        appeal: appeal,
        parent: schedule_hearing_task,
        assigned_to: HearingsManagement.singleton
      )
    end

    it "finds closest_ro for veteran" do
      VADotGovService = Fakes::VADotGovService
      verify_address_task.update!(status: "completed")

      expect(Appeal.first.closest_regional_office).to eq "RO17"
      expect(Appeal.first.available_hearing_locations.count).to eq 2
    end
  end
end

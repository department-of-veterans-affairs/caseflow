describe HearingAdminActionTask do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let!(:schedule_hearing_task) do
    ScheduleHearingTask.create!(
      appeal: appeal,
      parent: RootTask.find_or_create_by!(appeal: appeal),
      assigned_to: HearingsManagement.singleton
    )
  end

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

      expect(Veteran.first.closest_regional_office).to eq "RO14"
      expect(Veteran.first.available_hearing_locations.count).to eq 1
    end
  end
end

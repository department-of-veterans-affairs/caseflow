# frozen_string_literal: true

Rspec.describe Hearings::CreateBillOfMaterialsJob do
  let(:hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }
  let(:legacy_hearings) { (1..5).map { create(:legacy_hearing, :with_transcription_files) } }

  def hearings_in_work_order(hearings)
    hearings.map { |hearing| { hearing_id: hearing.id, hearing_type: hearing.class.to_s } }
  end

  let(:work_order) do
    {
      work_order_name: "",
      return_date: "",
      contractor_name: "",
      hearings: hearings_in_work_order
    }
end

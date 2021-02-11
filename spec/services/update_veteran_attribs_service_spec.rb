# frozen_string_literal: true

describe UpdateVeteranAttribsService do
  let(:veteranBob) { create(:veteran) }
  let(:veteranSam) { create(:veteran) }
  let(:appeal) { create(:appeal, veteran_file_number: veteranBob.file_number) }
  let(:appeal2) { create(:appeal, veteran_file_number: veteranSam.file_number) }
  let(:appeal_ids) { [appeal.uuid, appeal2.uuid] }

  context "with new veteran data in bgs" do
    let(:date_of_death) { "2020-12-08" }

    before do
      veteranBob.unload_bgs_record # force it to reload from BGS
      Fakes::BGSService.edit_veteran_record(veteranBob.file_number, :date_of_death, date_of_death)
      Fakes::BGSService.edit_veteran_record(veteranSam.file_number, :date_of_death, date_of_death)
    end

    subject { Veteran.update_veteran_attribs_service.update_veterans_for_appeals(appeal_ids) }

    it "updates our veteran_records date_of_death" do
      expect { subject }.not_to raise_error

      expect(veteranSam.reload.date_of_death).to eq(Date.parse(date_of_death))
      expect(veteranBob.reload.date_of_death).to eq(Date.parse(date_of_death))
    end
  end
end

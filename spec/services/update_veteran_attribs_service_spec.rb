# frozen_string_literal: true

describe UpdateVeteranAttribsService do
  let(:veteran) { create(:veteran) }
  let(:veteran2) { create(:veteran) }
  let(:appeal) { create(:appeal, veteran: veteran) }
  let(:appeal2) { create(:appeal, veteran: veteran2) }
  let(:appeal_ids) { [appeal.uuid, appeal2.uuid] }

  context "with new veteran data in bgs" do
    let(:date_of_death) { "2020-12-08" }

    before do
      # veteran.unload_bgs_record # force it to reload from BGS
      Fakes::BGSService.edit_veteran_record(veteran.file_number, :date_of_death, date_of_death)
      Fakes::BGSService.edit_veteran_record(veteran2.file_number, :date_of_death, date_of_death)
    end

    subject { UpdateVeteranAttribsService.update_veterans_for_appeals(appeal_ids) }

    it "updates our veteran_records date_of_death" do
      expect { subject }.not_to raise_error

      expect(veteran.reload.date_of_death).to eq(Date.parse(date_of_death))
      expect(veteran2.reload.date_of_death).to eq(Date.parse(date_of_death))
    end
  end
end

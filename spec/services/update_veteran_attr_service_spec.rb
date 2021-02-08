# frozen_string_literal: true

describe UpdateVeteranAttrService do
  let(:first_name) { "Bob" }
  let(:last_name) { "Boberson" }
  let(:middle_name) { "B" }
  let(:name_suffix) { "Esq" }
  let(:ssn) { "666000000" }
  let(:date_of_death) { "2021-1-12" }
  let(:veteranBob) do
    create(
      :veteran,
      first_name: first_name,
      last_name: last_name,
      middle_name: middle_name,
      name_suffix: name_suffix,
      ssn: ssn,
      date_of_death: date_of_death,
      bgs_veteran_record: {
        first_name: first_name,
        last_name: last_name,
        middle_name: middle_name,
        name_suffix: name_suffix,
        ssn: ssn,
        date_of_death: date_of_death
      }
    )
  end
  let(:sam_first_name) { "Sam" }
  let(:sam_last_name) { "Samerson" }
  let(:sam_middle_name) { "S" }
  let(:sam_name_suffix) { "Esq" }
  let(:sam_ssn) { "123456789" }
  let(:sam_date_of_death) { "2021-1-26" }
  let(:veteranSam) do
    create(
      :veteran,
      first_name: sam_first_name,
      last_name: sam_last_name,
      middle_name: sam_middle_name,
      name_suffix: sam_name_suffix,
      ssn: sam_ssn,
      date_of_death: sam_date_of_death,
      bgs_veteran_record: {
        first_name: sam_first_name,
        last_name: sam_last_name,
        middle_name: sam_middle_name,
        name_suffix: sam_name_suffix,
        ssn: sam_ssn,
        date_of_death: sam_date_of_death
      }
    )
  end
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

    subject { Veteran.update_veteran_attr_service.warm_veteran_cache_for_appeals(appeal_ids) }

    it "updates our veteran_records date_of_death" do
      expect { subject }.not_to raise_error

      expect(veteranSam.reload.date_of_death).to eq(Date.parse(date_of_death))
      expect(veteranBob.reload.date_of_death).to eq(Date.parse(date_of_death))
    end
  end
end

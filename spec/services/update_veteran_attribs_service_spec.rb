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
      Fakes::BGSService.edit_veteran_record(veteran.file_number, :date_of_death, date_of_death)
    end

    subject { UpdateVeteranAttribsService.update_veterans_for_appeals(appeal_ids) }

    it "runs update on all veterans linked to appeals that are passed in" do
      expect(subject.count).to eq(2)
    end

    it "updates date_of_death for a veteran with a change in BGS" do
      subject
      expect(veteran.reload.date_of_death).to eq(Date.parse(date_of_death))
    end

    it "doesn't update date_of_death if there is no change" do
      subject
      expect(veteran2.reload.date_of_death).to eq(nil)
    end
  end
end

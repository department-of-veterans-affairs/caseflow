# frozen_string_literal: true

require "helpers/sync_attributes_with_bgs"

describe SyncAttributesWithBGS do
  describe SyncAttributesWithBGS::VeteranCacheUpdater do
    subject { SyncAttributesWithBGS::VeteranCacheUpdater }
    context "#run_by_file_number" do
      let(:veteran) { create(:veteran, last_name: "INCORRECT") }
      let(:bgs_record) { Fakes::VeteranStore.new.fetch_and_inflate(veteran.file_number) }
      before do
        Fakes::BGSService.edit_veteran_record(veteran.file_number, :last_name, "CORRECT")
        allow(veteran).to receive(:bgs_record).and_return(bgs_record)
      end

      it "syncs veteran info with bgs" do
        expect(veteran.last_name).to eq "INCORRECT"
        expect(subject).to receive(:puts).with("Veteran Name: Bob  CORRECT")
        subject.run_by_file_number(veteran.file_number)
        veteran.reload
        expect(veteran.last_name).to eq "CORRECT"
      end

      context "errors" do
        context "find a veteran by file_number" do
          let(:file_number) { "12345678" }
          it "does not find a veteran" do
            expect(veteran.last_name).to eq "INCORRECT"
            expect(subject).to receive(:run_by_file_number).with(veteran.file_number).and_return("veteran not found")
            subject.run_by_file_number(veteran.file_number)
            veteran.reload
            expect(veteran.last_name).to eq "INCORRECT"
          end
        end
      end
    end
  end

  describe SyncAttributesWithBGS::PersonCacheUpdater do
    subject { SyncAttributesWithBGS::PersonCacheUpdater }
    let(:person) { create(:person, first_name: "INCORRECT", last_name: "INCORRECT", email_address: "bad@notgood.com") }
    context "#run_by_participant_id" do
      let(:bgs_person) { Fakes::BGSService.new.fetch_person_info(person.participant_id) }

      it "syncs person info with bgs" do
        expect(person.first_name).to eq "INCORRECT"
        expect(person.last_name).to eq "INCORRECT"
        expect(person.email_address).to eq "bad@notgood.com"
        expect(subject).to receive(:puts).with("Person Name: Tom Edward Brady")
        subject.run_by_participant_id(person.participant_id)
        person.reload
        expect(person.first_name).to eq "Tom"
        expect(person.last_name).to eq "Brady"
        expect(person.email_address).to eq "tom.brady@caseflow.gov"
        expect(person.date_of_birth).to eq Date.new(1998, 9, 5)
      end
    end

    context "errors" do
      let(:participant_id) { "12345678" }
      context "find a person by participant_id" do
        it "does not find person" do
          expect(subject).to receive(:run_by_participant_id).with(participant_id).and_return("person was not found")
          subject.run_by_participant_id(participant_id)
        end
      end

      context "bgs record not found" do
        before do
          allow(person).to receive(:fetch_bgs_record_by_participant_id).and_return(:not_found)
        end

        it "does not find a person bgs record" do
          expect(subject).to receive(:run_by_participant_id).with(participant_id).and_return("bgs record was not found")
          subject.run_by_participant_id(participant_id)
        end
      end

      context "person not valid" do
        before do
          allow(person).to receive(:save).and_return(false)
        end
        it "persons is not updated" do
          expect(subject).to receive(:run_by_participant_id).with(participant_id).and_return("person was not updated")
          subject.run_by_participant_id(participant_id)
        end
      end
    end
  end
end

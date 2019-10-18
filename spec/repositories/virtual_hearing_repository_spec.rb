# frozen_string_literal: true

require "support/vacols_database_cleaner"

describe VirtualHearingRepository, :all_dbs do
  context ".ready_for_deletion" do
    let(:virtual_hearing) { create(:virtual_hearing, :initialized, :active) }

    subject { VirtualHearingRepository.ready_for_deletion }

    context "for an AMA hearing" do
      let(:hearing_day) { create(:hearing_day) }
      let!(:hearing) { create(:hearing, hearing_day: hearing_day, virtual_hearing: virtual_hearing) }

      context "that was held" do
        let(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.now - 1.day) }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, :pending) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "on the day of" do
        let(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.now) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end

    context "for a Legacy hearing" do
      let(:hearing_date) { Time.zone.now }
      let(:hearing_day) { create(:hearing_day, scheduled_for: hearing_date) }
      let!(:legacy_hearing) do
        create(
          :legacy_hearing,
          hearing_day_id: hearing_day.id,
          virtual_hearing: virtual_hearing
        )
      end

      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, :pending) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "on the day of" do
        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end
  end

  context ".create_virtual_hearing_for_legacy_hearing" do
    let(:legacy_hearing) { create(:legacy_hearing) }

    subject { VirtualHearingRepository.create_virtual_hearing_for_legacy_hearing(legacy_hearing) }

    before do
      RequestStore[:current_user] = create(:user)
    end

    it "updates the hearing type on the VACOLS record to VIDEO" do
      expect(subject.reload.hearing.request_type).to eq "R"
    end
  end
end

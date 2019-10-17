# frozen_string_literal: true

require "support/vacols_database_cleaner"

describe VirtualHearingRepository,:all_dbs do
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

    context "for a Legacy hearing", focus: true do
      let(:hearing_date) { Time.zone.now }
      let(:hearing_day) { create(:hearing_day, scheduled_for: hearing_date) }
      let!(:case_hearing) do
        create(
          :case_hearing,
          hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date),
          vdkey: hearing_day.id
        )
      end
      let!(:legacy_hearing) do
        create(
          :legacy_hearing,
          case_hearing: case_hearing,
          hearing_day: hearing_day,
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
end

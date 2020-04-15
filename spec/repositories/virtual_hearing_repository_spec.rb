# frozen_string_literal: true

describe VirtualHearingRepository, :all_dbs do
  context ".ready_for_deletion" do
    let(:regional_office) { "RO42" }
    let(:hearing_date) { Time.zone.now }
    let(:hearing_day) do
      create(
        :hearing_day,
        regional_office: regional_office,
        scheduled_for: hearing_date,
        request_type: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:hearing) { create(:hearing, regional_office: regional_office, hearing_day: hearing_day) }
    let!(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :active, hearing: hearing) }

    subject { VirtualHearingRepository.ready_for_deletion }

    context "for an AMA hearing" do
      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "for cancelled hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, status: :cancelled, hearing: hearing) }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "on the day of" do
        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end

    context "for a Legacy hearing" do
      let(:hearing) do
        create(:legacy_hearing, regional_office: regional_office, hearing_day_id: hearing_day.id)
      end

      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for cancelled hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, status: :cancelled, hearing: hearing) }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, status: :pending, hearing: hearing) }

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

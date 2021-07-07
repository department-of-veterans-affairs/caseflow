# frozen_string_literal: true

describe HearingDayFilledSlotsQuery do
  subject { HearingDayFilledSlotsQuery.new([hearing_day_one, hearing_day_two]).call }

  context "hearings days with mix of hearings and legacy hearings" do
    let(:hearing_day_one) { create(:hearing_day) }
    let(:hearing_day_two) { create(:hearing_day) }
    let!(:hearings) do
      [
        create(:hearing, :held, hearing_day: hearing_day_one),
        create(:hearing, :cancelled, hearing_day: hearing_day_one),
        create(:hearing, :scheduled_in_error, hearing_day: hearing_day_two),
        create(:hearing, hearing_day: hearing_day_two), # nil disposition
        create(
          :legacy_hearing,
          hearing_day: hearing_day_one,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:held]
        ),
        create(
          :legacy_hearing,
          hearing_day: hearing_day_one,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:scheduled_in_error]
        ),
        create(
          :legacy_hearing,
          hearing_day: hearing_day_two,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:postponed]
        ),
        create(:legacy_hearing, hearing_day: hearing_day_two) # nil disposition
      ]
    end

    it "returns correct values", :aggregate_failures do
      subject
      expect(subject[hearing_day_one.id]).to eq 2
      expect(subject[hearing_day_two.id]).to eq 2
    end
  end
end

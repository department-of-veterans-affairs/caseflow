# frozen_string_literal: true

describe Hearings::TravelBoardHearingSyncJob do
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:vacols_ids) { %w[123450 123451 123452 123453 123454 123455 123456 123457 123458 123459] }
  let(:new_caseflow_vacols_ids) { %w[123450 123451 123452 123453 123455 123458 123459] }
  let(:legacy_appeal) { create(:legacy_appeal) }
  let(:cases) {
    create_list(:case, 10) do |vacols_case, i|
      bfhr = (i == 4 || i == 7) ? "1" : VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:TRAVEL_BOARD][:vacols_value]
      vacols_case.update!(
        bfkey: vacols_ids[i],
        bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
        bfhr: bfhr
      )
    end
  }

  describe "#perform" do
    subject { Hearings::TravelBoardHearingSyncJob.new }

    before do
      current_user
      vacols_ids
      cases
      legacy_appeal
    end

    it "fetches and creates travel board legacy appeals that were not in caseflow before" do
      expect(subject.send(:fetch_vacols_travel_board_appeals, LegacyAppeal.all.pluck(:vacols_id), 250)
        .pluck(:vacols_id)).to eq(new_caseflow_vacols_ids)
    end
  end
end

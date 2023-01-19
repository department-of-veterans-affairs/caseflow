# frozen_string_literal: true

describe Hearings::TravelBoardHearingSyncJob do
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:vacols_ids) { %w[12340 12341 12342 12343 12344 12345 12346 12347 12348 12349] }
  let(:legacy_appeal) { create(:legacy_appeal) }
  let(:cases) {
    create_list(:case, 10) do |vacols_case, i|
      bfcurloc = (i == 4 || i == 7) ? "1" : LegacyAppeal::LOCATION_CODES[:schedule_hearing]
      vacols_case.update!(bfkey: vacols_ids[i], bfcurloc: bfcurloc)
    end
  }

  describe "#perform" do
    subject { Hearings::TravelBoardHearingSyncJob.new.perform }

    before do
      current_user
      vacols_ids
      cases
      legacy_appeal
    end

    it "fetches and creates travel board legacy appeals that were not in caseflow before" do
      expect(LegacyAppeal.all.pluck(:vacols_id))
      subject
    end
  end
end

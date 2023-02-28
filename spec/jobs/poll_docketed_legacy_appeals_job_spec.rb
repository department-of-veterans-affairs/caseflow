# frozen_string_literal: true

describe PollDocketedLegacyAppealsJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }

  describe "polling for docketed appeals" do
    before do
      Seeds::NotificationEvents.new.seed!
    end

    let!(:today) { Time.now.utc.iso8601 }
    let!(:yesterday) { 1.day.ago.getutc.iso8601 }

    let(:vacols_ids) { %w[12340 12341 12342 12343 12344 12345 12346 12347 12348 12349] }
    let(:bfac_codes) { %w[1 3 7] }

    # rubocop:disable Style/BlockDelimiters
    let(:cases) {
      create_list(:case, 10) do |vacols_case, i|
        bfac = (i == 4) ? "4" : bfac_codes.sample
        vacols_case.update!(bfkey: vacols_ids[i], bfac: bfac)
      end
    }
    let(:legacy_appeals) {
      create_list(:legacy_appeal, 10) do |appeal, i|
        appeal.update!(vacols_id: vacols_ids[i])
      end
    }
    let(:claim_histories) {
      create_list(:priorloc, 10) do |claim_history, i|
        locstto = (i == 3) ? "02" : "01"
        locdout = i.even? ? today : yesterday
        claim_history.update!(lockey: vacols_ids[i], locstto: locstto, locdout: locdout)
      end
    }
    let(:notification) {
      create(:notification,
             appeals_id: "12342",
             appeals_type: "LegacyAppeal",
             event_date: today,
             event_type: "Appeal docketed",
             notification_type: "Email",
             notified_at: today)
    }
    let(:filtered_claim_histories) {
      claim_histories_copy = claim_histories.dup
      claim_histories_copy.slice!(2, 4)
      claim_histories_copy
    }

    let(:recent_docketed_appeal_ids) { %w[12340 12342 12346 12348] }

    let(:filtered_docketed_appeal_ids) { %w[12340 12346 12348] }

    let(:query) {
      "INNER JOIN priorloc
      ON brieff.bfkey = priorloc.lockey WHERE brieff.bfac IN ('1','3','7')
      AND locstto = '01' AND trunc(locdout) = trunc(sysdate)"
    }
    # rubocop:enable Style/BlockDelimiters

    before(:each) do
      cases
      legacy_appeals
      claim_histories
      notification
    end

    it "should filter for all cases that have been recently docketed" do
      expect(PollDocketedLegacyAppealsJob.new.most_recent_docketed_appeals(query)).to eq(recent_docketed_appeal_ids)
    end

    it "should filter for all legacy appeals that havent already gotten a notification yet" do
      expect(PollDocketedLegacyAppealsJob.perform_now).to eq(filtered_docketed_appeal_ids)
    end
  end
end

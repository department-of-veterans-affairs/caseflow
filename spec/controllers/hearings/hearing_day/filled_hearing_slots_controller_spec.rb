# frozen_string_literal: true

RSpec.describe Hearings::HearingDay::FilledHearingSlotsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Edit HearSched", "Build HearSched"]) }

  describe "#index" do
    context "with invalid params" do
      let(:invalid_hearing_day_id) { "invalid" }
      it "does not return anything", :aggregate_failures do
        get :index, params: { hearing_day_id: invalid_hearing_day_id }, as: :json
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["filled_hearing_slots"]).to eq(nil)
      end
    end

    context "hearing day with multiple hearings" do
      let(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.now.to_date) }
      let(:ama_hearing) { create(:hearing, hearing_day: hearing_day) }
      let(:ama_poa_name) { "Ama Attorney" }
      let!(:ama_poa) do
        create(
          :bgs_power_of_attorney,
          claimant_participant_id: ama_hearing.appeal.claimant.participant_id,
          representative_name: ama_poa_name
        )
      end
      let(:legacy_hearing) do
        create(
          :legacy_hearing,
          hearing_day: hearing_day,
          scheduled_for: Time.use_zone("America/New_York") { Time.zone.now.change(hour: 12, min: 0) }
        )
      end
      let(:legacy_poa_name) { "Legacy Attorney" }
      let!(:legacy_poa) do
        create(
          :bgs_power_of_attorney,
          file_number: legacy_hearing.appeal.veteran_file_number,
          representative_name: legacy_poa_name
        )
      end

      let(:expected_keys) { %w[external_id hearing_time issue_count docket_number docket_name poa_name] }

      it "returns correct data", :aggregate_failures do
        get :index, params: { hearing_day_id: hearing_day.id }, as: :json
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["filled_hearing_slots"].size).to eq 2
        expect(response_body["filled_hearing_slots"].first.keys).to match_array(expected_keys)
        expect(response_body["filled_hearing_slots"].second.keys).to match_array(expected_keys)
        expect(response_body["filled_hearing_slots"].map { |res| res["hearing_time"] })
          .to match_array(["08:30", "12:00"])
        expect(response_body["filled_hearing_slots"].map { |res| res["issue_count"] })
          .to match_array([ama_hearing.current_issue_count, legacy_hearing.current_issue_count])
        expect(response_body["filled_hearing_slots"].map { |res| res["docket_number"] })
          .to match_array([ama_hearing.docket_number, legacy_hearing.docket_number])
        expect(response_body["filled_hearing_slots"].map { |res| res["docket_name"] })
          .to match_array([ama_hearing.docket_name, legacy_hearing.docket_name])
        expect(response_body["filled_hearing_slots"].map { |res| res["poa_name"] })
          .to match_array([ama_poa_name, legacy_poa_name])
        expect(response_body["filled_hearing_slots"].map { |res| res["external_id"] })
          .to match_array([ama_hearing.external_id, legacy_hearing.external_id])
      end
    end
  end
end

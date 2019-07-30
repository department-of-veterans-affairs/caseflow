# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.describe HearingsController, :all_dbs, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:legacy_hearing) { create(:legacy_hearing) }

  describe "PATCH update" do
    it "should be successful" do
      params = { notes: "Test",
                 hold_open: 30,
                 transcript_requested: false,
                 aod: :granted,
                 disposition: :held,
                 hearing_location_attributes: {
                   facility_id: "vba_301"
                 },
                 prepped: true }
      patch :update, as: :json, params: { id: legacy_hearing.external_id, hearing: params }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["notes"]).to eq "Test"
      expect(response_body["hold_open"]).to eq 30
      expect(response_body["transcript_requested"]).to eq false
      expect(response_body["aod"]).to eq "granted"
      expect(response_body["disposition"]).to eq "held"
      expect(response_body["location"]["facility_id"]).to eq "vba_301"
      expect(response_body["prepped"]).to eq true
    end

    context "when updating an ama hearing" do
      let!(:hearing) { create(:hearing, :with_tasks) }

      it "should update an ama hearing" do
        params = { notes: "Test",
                   transcript_requested: false,
                   disposition: :held,
                   hearing_location_attributes: {
                     facility_id: "vba_301"
                   },
                   prepped: true,
                   evidence_window_waived: true }
        patch :update, as: :json, params: { id: hearing.external_id, hearing: params }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["notes"]).to eq "Test"
        expect(response_body["transcript_requested"]).to eq false
        expect(response_body["disposition"]).to eq "held"
        expect(response_body["prepped"]).to eq true
        expect(response_body["location"]["facility_id"]).to eq "vba_301"
        expect(response_body["evidence_window_waived"]).to eq true
      end
    end

    it "should return not found" do
      patch :update, params: { id: "78484", hearing: { notes: "Test", hold_open: 30, transcript_requested: false } }
      expect(response.status).to eq 404
    end
  end

  describe "#show" do
    let!(:hearing) { create(:hearing, :with_tasks) }

    it "returns hearing details" do
      get :show, as: :json, params: { id: hearing.external_id }

      expect(response.status).to eq 200
    end
  end

  describe "#find_closest_hearing_locations" do
    before do
      stub_const("VADotGovService", Fakes::VADotGovService)
    end

    context "for AMA appeals" do
      let!(:appeal) { create(:appeal) }

      it "returns an address" do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 200
      end
    end

    context "for legacy appeals" do
      let!(:vacols_case) { create(:case) }
      let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

      it "returns an address" do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: legacy_appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 200
      end
    end

    context "when returns unknown error" do
      let(:appeal) { create(:appeal) }

      before do
        error = JSON::ParserError.new

        allow(VADotGovService).to receive(:send_va_dot_gov_request).and_raise(error)
      end

      it "returns an error response" do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 500
        expect(JSON.parse(response.body)["message"]).to eq "JSON::ParserError"
      end
    end

    context "when an address cannot be found" do
      let(:appeal) { create(:appeal) }

      before do
        message = {
          "messages" => [
            {
              "key" => "AddressCouldNotBeFound"
            }
          ]
        }

        error = Caseflow::Error::VaDotGovServerError.new(code: "500", message: message)

        allow(VADotGovService).to receive(:send_va_dot_gov_request).and_raise(error)
      end

      it "returns an error response" do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 400
        expect(JSON.parse(response.body)["message"]).to eq "AddressCouldNotBeFound"
      end
    end
  end
end

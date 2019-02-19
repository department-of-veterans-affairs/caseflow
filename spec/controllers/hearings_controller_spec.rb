RSpec.describe HearingsController, type: :controller do
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
      let!(:hearing) { create(:hearing) }

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

    context "when setting disposition as postponed" do
      let!(:scheduled_for) { Date.new(2019, 4, 2).in_time_zone.to_s }
      let!(:hearing_day) do
        HearingDay.create_hearing_day(
          request_type: HearingDay::REQUEST_TYPES[:central],
          scheduled_for: scheduled_for,
          room: "123",
          judge_id: "456"
        )
      end

      let!(:params) do
        { notes: "Test",
          hold_open: 30,
          transcript_requested: false,
          aod: :granted,
          add_on: true,
          disposition: :postponed,
          prepped: true }
      end

      let!(:master_record_params) do
        {
          id: hearing_day[:id],
          time: {
            "h" => "9",
            "m" => "00",
            "offset" => "-500"
          },
          hearing_location_attributes: {
            "facility_id" => "vba_301"
          }
        }
      end

      context "for a legacy hearing" do
        it "should create a new VACOLS hearing and LegacyHearing" do
          patch :update, as: :json, params: {
            id: legacy_hearing.external_id, hearing: params, master_record_updated: master_record_params
          }
          expect(response.status).to eq 200

          binding.pry

          expect(LegacyHearing.last.location.facility_id).to eq "vba_301"

          # this is failing because the VACOLS insert writes assuming UTC but with a ET value.
          # e.g. "2019-04-02 10:00:00"
          expect(VACOLS::CaseHearing.find_by(vdkey: hearing_day[:id]).hearing_date).to eq(
            Time.new(2019, 4, 2, 10).in_time_zone("Eastern Time (US & Canada)")
          )
        end
      end

      context "for an AMA hearing" do
        let(:hearing) { create(:hearing, scheduled_time: Time.zone.now) }
        let!(:params) do
          { notes: "Test",
            disposition: :postponed }
        end

        it "should create a new hearing" do
          patch :update, as: :json, params: {
            id: hearing.external_id, hearing: params, master_record_updated: master_record_params
          }

          expect(Hearing.last.location.facility_id).to eq "vba_301"
        end
      end
    end

    it "should return not found" do
      patch :update, params: { id: "78484", hearing: { notes: "Test", hold_open: 30, transcript_requested: false } }
      expect(response.status).to eq 404
    end
  end

  describe "#show" do
    let!(:hearing) { create(:hearing) }

    it "returns hearing details" do
      get :show, as: :json, params: { id: hearing.external_id }

      expect(response.status).to eq 200
    end
  end

  describe "#find_closest_hearing_locations" do
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
  end
end

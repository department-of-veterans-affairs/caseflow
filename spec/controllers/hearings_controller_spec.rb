RSpec.describe HearingsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let(:hearing) { create(:legacy_hearing) }

  describe "PATCH update" do
    it "should be successful" do
      params = { notes: "Test",
                 hold_open: 30,
                 transcript_requested: false,
                 aod: :granted,
                 disposition: :held,
                 prepped: true }
      patch :update, as: :json, params: { id: hearing.external_id, hearing: params }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["notes"]).to eq "Test"
      expect(response_body["hold_open"]).to eq 30
      expect(response_body["transcript_requested"]).to eq false
      expect(response_body["aod"]).to eq "granted"
      expect(response_body["disposition"]).to eq "held"
      expect(response_body["prepped"]).to eq true
    end

    context "when updating an ama hearing" do
      let!(:hearing) { create(:hearing) }

      it "should update an ama hearing" do
        params = { notes: "Test",
                   transcript_requested: false,
                   disposition: :held,
                   prepped: true,
                   evidence_window_waived: true }
        patch :update, as: :json, params: { id: hearing.external_id, hearing: params }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["notes"]).to eq "Test"
        expect(response_body["transcript_requested"]).to eq false
        expect(response_body["disposition"]).to eq "held"
        expect(response_body["prepped"]).to eq true
        expect(response_body["evidence_window_waived"]).to eq true
      end
    end

    context "when setting disposition as postponed" do
      let(:scheduled_for) { Date.new(2019, 4, 2) }
      let(:hearing_day) do
        HearingDay.create_hearing_day(
          request_type: "C",
          scheduled_for: scheduled_for,
          room: "123",
          judge_id: "456"
        )
      end

      before { Time.zone = "America/New_York" }

      it "should create a new hearing" do
        params = { notes: "Test",
                   hold_open: 30,
                   transcript_requested: false,
                   aod: :granted,
                   add_on: true,
                   disposition: :postponed,
                   master_record_updated: {
                     "id" => hearing_day[:id],
                     "time" => {
                       "h" => "9",
                       "m" => "00",
                       "offset" => "-500"
                     }
                   },
                   prepped: true }
        patch :update, as: :json, params: { id: hearing.external_id, hearing: params }
        expect(response.status).to eq 200

        expect(VACOLS::CaseHearing.find_by(vdkey: hearing_day[:id]).hearing_date).to eq(
          Time.new(2019, 4, 2, 10).in_time_zone("Eastern Time (US & Canada)")
        )
      end
    end

    it "should return not found" do
      patch :update, params: { id: "78484", hearing: { notes: "Test", hold_open: 30, transcript_requested: false } }
      expect(response.status).to eq 404
    end
  end
end

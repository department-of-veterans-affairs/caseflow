# frozen_string_literal: true

RSpec.describe HearingsController, :all_dbs, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:legacy_hearing) { create(:legacy_hearing) }
  let(:ama_hearing) { create(:hearing) }

  describe "PATCH update" do
    it "should be successful", :aggregate_failures do
      params = {
        notes: "Test",
        hold_open: 30,
        transcript_requested: false,
        aod: :granted,
        disposition: :held,
        hearing_location_attributes: {
          facility_id: "vba_301"
        },
        prepped: true
      }
      patch :update, as: :json, params: { id: legacy_hearing.external_id, hearing: params }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["data"]
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

      it "should update an ama hearing", :aggregate_failures do
        params = {
          notes: "Test",
          transcript_requested: false,
          disposition: :held,
          hearing_location_attributes: {
            facility_id: "vba_301"
          },
          prepped: true,
          evidence_window_waived: true
        }
        patch :update, as: :json, params: { id: hearing.external_id, hearing: params }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["data"]
        expect(response_body["notes"]).to eq "Test"
        expect(response_body["transcript_requested"]).to eq false
        expect(response_body["disposition"]).to eq "held"
        expect(response_body["prepped"]).to eq true
        expect(response_body["location"]["facility_id"]).to eq "vba_301"
        expect(response_body["evidence_window_waived"]).to eq true
      end
    end

    context "when updating an existing hearing to a virtual hearing" do
      let(:hearing) { create(:hearing, regional_office: "RO42") }
      let(:virtual_hearing_params) { {} }

      subject do
        hearing_params = {
          notes: "Notes",
          virtual_hearing_attributes: virtual_hearing_params
        }
        patch_params = {
          id: hearing.external_id,
          hearing: hearing_params
        }

        patch :update, as: :json, params: patch_params
        response
      end

      context "without any params", :aggregate_failures do
        it "returns 200 status code" do
          expect(subject.status).to eq(200)
        end
        it "hearing was not changed " do
          expect(hearing.virtual?).to eq(false)
        end
      end

      context "without any veteran email" do
        let(:virtual_hearing_params) do
          {
            representative_email: "new_representative_email@caseflow.gov"
          }
        end

        it "returns 400 status code" do
          expect(subject.status).to eq(400)
        end

        context "with hearing that already has a virtual hearing" do
          let(:hearing) { create(:hearing, regional_office: "RO42") }
          let!(:virtual_hearing) do
            create(
              :virtual_hearing,
              hearing: hearing,
              veteran_email: "existing_veteran_email@caseflow.gov",
              veteran_email_sent: true
            )
          end

          it "returns expected status and has the expected side effects", :aggregate_failures do
            expect(subject.status).to eq(200)
            virtual_hearing.reload
            expect(virtual_hearing.veteran_email).to eq("existing_veteran_email@caseflow.gov")
            expect(virtual_hearing.veteran_email_sent).to eq(true)
            expect(virtual_hearing.representative_email).to eq("new_representative_email@caseflow.gov")
          end
        end
      end

      context "with invalid emails" do
        let(:virtual_hearing_params) do
          {
            veteran_email: "veteran",
            judge_email: "!@#$%",
            representative_email: "representative_email"
          }
        end

        it "returns 400 status code" do
          expect(subject.status).to eq(400)
        end
      end

      context "with all email params" do
        let(:virtual_hearing_params) do
          {
            veteran_email: "new_veteran_email@caseflow.gov",
            representative_email: "new_representative_email@caseflow.gov"
          }
        end

        it "returns expected status and has expected side effects", :aggregate_failures do
          expect(subject.status).to eq(200)
          expect(VirtualHearing.first).to_not eq(nil)
          expect(VirtualHearing.first.hearing_id).to eq(hearing.id)
          expect(VirtualHearing.first.veteran_email).to eq("new_veteran_email@caseflow.gov")
          expect(VirtualHearing.first.representative_email).to eq("new_representative_email@caseflow.gov")
        end

        it "kicks off CreateConferenceJob and updates virtual_hearing table", :aggregate_failures do
          subject
          expect(VirtualHearing.first.establishment.submitted?).to eq(true)
          expect(VirtualHearing.first.status).to eq("active")
          expect(VirtualHearing.first.conference_id).to_not eq(nil)
          expect(VirtualHearing.first.veteran_email_sent).to eq(true)
          expect(VirtualHearing.first.representative_email_sent).to eq(true)
        end

        context "with hearing that already has a virtual hearing" do
          let(:hearing) { create(:hearing, regional_office: "RO42") }

          let!(:virtual_hearing) do
            create(
              :virtual_hearing,
              hearing: hearing,
              veteran_email: "existing_veteran_email@caseflow.gov",
              representative_email: "existing_rep_email@casfelow.gov"
            )
          end

          it "returns expected status and updates the existing hearing", :aggregate_failures do
            expect(subject.status).to eq(200)
            virtual_hearing.reload
            expect(virtual_hearing.veteran_email).to eq("new_veteran_email@caseflow.gov")
            expect(virtual_hearing.representative_email).to eq("new_representative_email@caseflow.gov")
          end
        end
      end

      context "with the status param and existing virtual hearing" do
        let(:hearing) { create(:hearing, regional_office: "RO42") }

        let!(:virtual_hearing) do
          create(
            :virtual_hearing,
            :all_emails_sent,
            hearing: hearing,
            conference_id: "000000"
          )
        end
        let(:virtual_hearing_params) do
          {
            status: "cancelled"
          }
        end

        it "returns the expected status and updates the virtual hearing", :aggregate_failures do
          expect(subject.status).to eq(200)
          virtual_hearing.reload
          expect(virtual_hearing.cancelled?).to eq(true)
        end
      end
    end

    context "when updating the AOD" do
      it "should return a 200 if empty aod" do
        params = {
          id: ama_hearing.external_id,
          advance_on_docket_motion: {},
          hearing: { notes: "Test" }
        }
        patch :update, as: :json, params: params
        expect(response.status).to eq 200
      end

      it "should return a 200 and update aod if provided", :aggregate_failures, skip: "flake AOD present" do
        params = {
          id: ama_hearing.external_id,
          advance_on_docket_motion: {
            user_id: user.id,
            person_id: ama_hearing.appeal.appellant.id,
            reason: AdvanceOnDocketMotion.reasons[:age],
            granted: true
          },
          hearing: { notes: "Test" }
        }
        patch :update, as: :json, params: params
        expect(response.status).to eq 200
        ama_hearing.reload
        expect(ama_hearing.advance_on_docket_motion.person.id).to eq ama_hearing.appeal.appellant.id
        expect(ama_hearing.advance_on_docket_motion.reason).to eq AdvanceOnDocketMotion.reasons[:age]
        expect(ama_hearing.advance_on_docket_motion.granted).to eq true
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
      let!(:legacy_appeal) { create(:legacy_appeal, :with_veteran_address, vacols_case: vacols_case) }

      it "returns an address" do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: legacy_appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 200
      end
    end

    context "when facility request fails" do
      let(:appeal) { create(:appeal) }

      before do
        facilities_response = ExternalApi::VADotGovService::FacilitiesResponse.new(
          HTTPI::Response.new(200, {}, {}.to_json)
        )
        allow(facilities_response).to receive(:data).and_return([])
        allow(facilities_response).to receive(:code).and_return(500)
        allow(VADotGovService).to receive(:get_distance).and_return(facilities_response)
      end

      it "returns an error response", :aggregate_failures do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 500
        expect(JSON.parse(response.body).dig("errors").first.dig("detail"))
          .to eq("An unexpected error occured when attempting to map veteran.")
      end
    end

    context "when an address cannot be found" do
      let(:appeal) { create(:appeal) }

      before do
        valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(
          HTTPI::Response.new(200, {}, {}.to_json)
        )
        allow(valid_address_response).to receive(:data).and_return([])
        allow(valid_address_response).to receive(:code).and_return(500)
        allow_any_instance_of(VaDotGovAddressValidator).to receive(:valid_address_response)
          .and_return(valid_address_response)
      end

      it "returns an error response", :aggregate_failures do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: appeal.external_id, regional_office: "RO13" }

        expect(response.status).to eq 500
        expect(JSON.parse(response.body).dig("errors").first.dig("detail"))
          .to eq("An unexpected error occured when attempting to map veteran.")
      end
    end
  end
end

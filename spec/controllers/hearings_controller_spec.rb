# frozen_string_literal: true

RSpec.describe HearingsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:legacy_hearing) { create(:legacy_hearing) }
  let(:ama_hearing) { create(:hearing) }
  let(:cheyenne_ro_mountain) { "RO42" }
  let(:oakland_ro_pacific) { "RO43" }
  let(:baltimore_ro_eastern) { "RO13" }
  let(:timezone) { "America/New_York" }
  let(:disposition) { nil }

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

    shared_context "based on hearing disposition" do
      before do
        # Stub out the job starting, so we can check to make sure the email
        # sent flags are set properly.
        allow(VirtualHearings::CreateConferenceJob).to receive(:perform_now)
        allow(VirtualHearings::DeleteConferencesJob).to receive(:perform_now)
        hearing.update!(disposition: disposition)
      end

      shared_examples "does not set email flags" do
        it "returns the expected status and updates the virtual hearing", :aggregate_failures do
          expect(subject.status).to eq(200)

          virtual_hearing.reload
          expect(virtual_hearing.appellant_email_sent).to eq(true)
          expect(virtual_hearing.representative_email_sent).to eq(true)
          expect(virtual_hearing.judge_email_sent).to eq(true)
        end
      end

      context "when hearing disposition is postponed" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.to_h[:postponed] }

        include_examples "does not set email flags"
      end

      context "when hearing disposition is cancelled" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.to_h[:cancelled] }

        include_examples "does not set email flags"
      end

      context "when hearing disposition is scheduled_in_error" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.to_h[:scheduled_in_error] }

        include_examples "does not set email flags"
      end
    end

    context "when updating an existing hearing to a virtual hearing", focus: true do
      let(:judge) { create(:user, station_id: User::BOARD_STATION_ID, email: "new_judge_email@caseflow.gov") }
      let(:hearing) { create(:hearing, regional_office: cheyenne_ro_mountain, judge: judge) }
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
          let(:hearing) { create(:hearing, regional_office: cheyenne_ro_mountain) }
          let!(:virtual_hearing) do
            create(
              :virtual_hearing,
              :initialized,
              status: :active,
              hearing: hearing,
              appellant_email: "existing_veteran_email@caseflow.gov",
              appellant_email_sent: true,
              judge_email: "existing_judge_email@caseflow.gov",
              judge_email_sent: true,
              representative_email: nil
            )
          end

          it "returns expected status and has the expected side effects", :aggregate_failures do
            expect(subject.status).to eq(200)
            virtual_hearing.reload
            expect(virtual_hearing.appellant_email).to eq("existing_veteran_email@caseflow.gov")
            expect(virtual_hearing.appellant_email_sent).to eq(true)
            expect(virtual_hearing.judge_email).to eq("existing_judge_email@caseflow.gov")
            expect(virtual_hearing.judge_email_sent).to eq(true)
            expect(virtual_hearing.representative_email).to eq("new_representative_email@caseflow.gov")
          end

          include_context "based on hearing disposition"
        end
      end

      context "with invalid emails" do
        let(:virtual_hearing_params) do
          {
            appellant_email: "veteran",
            judge_email: "!@#$%",
            representative_email: "representative_email"
          }
        end

        it "returns 400 status code" do
          expect(subject.status).to eq(400)
        end
      end

      context "with emails with whitespaces" do
        let(:virtual_hearing_params) do
          {
            appellant_email: "veteran@email.com     ",
            representative_email: "        representative@email.com  "
          }
        end

        it "returns the expected status and updates the virtual hearing", :aggregate_failures do
          expect(subject.status).to eq(200)

          expect(VirtualHearing.first.appellant_email).to eq("veteran@email.com")
          expect(VirtualHearing.first.representative_email).to eq("representative@email.com")
        end
      end

      context "with all email params" do
        let(:virtual_hearing_params) do
          {
            appellant_email: "new_veteran_email@caseflow.gov",
            representative_email: "new_representative_email@caseflow.gov"
          }
        end

        it "returns expected status and has expected side effects", :aggregate_failures do
          expect(subject.status).to eq(200)
          expect(VirtualHearing.first).to_not eq(nil)
          expect(VirtualHearing.first.hearing_id).to eq(hearing.id)
          expect(VirtualHearing.first.appellant_email).to eq("new_veteran_email@caseflow.gov")
          expect(VirtualHearing.first.judge_email).to eq("new_judge_email@caseflow.gov")
          expect(VirtualHearing.first.representative_email).to eq("new_representative_email@caseflow.gov")
        end

        it "kicks off CreateConferenceJob and updates virtual_hearing table", :aggregate_failures do
          subject
          expect(VirtualHearing.first.establishment.submitted?).to eq(true)
          expect(VirtualHearing.first.status).to eq(:active)
          expect(VirtualHearing.first.conference_id).to_not eq(nil)
          expect(VirtualHearing.first.appellant_email_sent).to eq(true)
          expect(VirtualHearing.first.judge_email_sent).to eq(true)
          expect(VirtualHearing.first.representative_email_sent).to eq(true)
        end

        context "with hearing that already has a virtual hearing" do
          let(:hearing) { create(:hearing, regional_office: cheyenne_ro_mountain) }

          let!(:virtual_hearing) do
            create(
              :virtual_hearing,
              :initialized,
              status: :active,
              hearing: hearing,
              appellant_email: "existing_veteran_email@caseflow.gov",
              appellant_email_sent: true,
              judge_email: "judge@email.com",
              judge_email_sent: true,
              representative_email: "existing_rep_email@casfelow.gov",
              representative_email_sent: true
            )
          end

          it "returns expected status and updates the existing hearing", :aggregate_failures do
            expect(subject.status).to eq(200)
            virtual_hearing.reload
            expect(virtual_hearing.appellant_email).to eq("new_veteran_email@caseflow.gov")
            expect(virtual_hearing.representative_email).to eq("new_representative_email@caseflow.gov")
          end

          include_context "based on hearing disposition"
        end
      end

      context "with the status param and existing virtual hearing" do
        let(:hearing) { create(:hearing, regional_office: cheyenne_ro_mountain) }

        let!(:virtual_hearing) do
          create(
            :virtual_hearing,
            :all_emails_sent,
            status: :active,
            hearing: hearing,
            conference_id: "000000"
          )
        end
        let(:virtual_hearing_params) do
          {
            request_cancelled: true
          }
        end

        before do
          # Stub out the job starting, so we can check to make sure the email
          # sent flags are set properly.
          allow(VirtualHearings::DeleteConferencesJob).to receive(:perform_now)
        end

        it "returns the expected status and updates the virtual hearing", :aggregate_failures do
          expect(subject.status).to eq(200)
          virtual_hearing.reload
          expect(virtual_hearing.cancelled?).to eq(true)
          # Ensure email_sent flags are not set for judge recipient
          expect(virtual_hearing.appellant_email_sent).to eq(false)
          expect(virtual_hearing.representative_email_sent).to eq(false)
          expect(virtual_hearing.judge_email_sent).to eq(true)
        end

        include_context "based on hearing disposition"
      end

      context "with valid appellant_tz" do
        let(:virtual_hearing_params) do
          {
            appellant_email: "new_veteran_email@caseflow.gov",
            appellant_tz: timezone
          }
        end

        it "returns expected status and has expected side effects", :aggregate_failures do
          expect(subject.status).to eq(200)
          expect(hearing.reload.virtual_hearing.appellant_tz).to eq(timezone)
        end
      end

      context "with valid representative_tz" do
        let(:virtual_hearing_params) do
          {
            appellant_email: "new_veteran_email@caseflow.gov",
            representative_email: "new_rep_email@caseflow.gov",
            representative_tz: timezone
          }
        end

        it "returns expected status and has expected side effects", :aggregate_failures do
          expect(subject.status).to eq(200)
          expect(hearing.reload.virtual_hearing.representative_tz).to eq(timezone)
        end
      end
    end

    context "when updating the judge of an existing virtual hearing" do
      let(:new_judge) { create(:user, station_id: User::BOARD_STATION_ID, email: "new_judge_email@caseflow.gov") }
      let(:hearing) { create(:hearing, regional_office: cheyenne_ro_mountain) }
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :initialized,
          status: :active,
          hearing: hearing,
          appellant_email: "existing_veteran_email@caseflow.gov",
          appellant_email_sent: true,
          judge_email: "existing_judge_email@caseflow.gov",
          judge_email_sent: true,
          representative_email: "existing_representative_email@caseflow.gov",
          representative_email_sent: true
        )
      end

      before do
        # Stub out the job starting, so we can check to make sure the email
        # sent flags are set properly.
        allow(VirtualHearings::CreateConferenceJob).to receive(:perform_now)
      end

      subject do
        patch_params = {
          id: hearing.external_id,
          hearing: {
            judge_id: new_judge.id
          }
        }

        patch :update, as: :json, params: patch_params
        response
      end

      it "updates the judge's email on the virtual hearing", :aggregate_failures do
        expect(subject.status).to eq(200)

        virtual_hearing.reload

        expect(virtual_hearing.hearing.judge_id).to eq(new_judge.id)
        expect(virtual_hearing.judge_email).to eq(new_judge.email)

        expect(virtual_hearing.judge_email_sent).to eq(false)
        expect(virtual_hearing.appellant_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
      end

      include_context "based on hearing disposition"
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
            reason: Constants.AOD_REASONS.age,
            granted: true
          },
          hearing: { notes: "Test" }
        }
        patch :update, as: :json, params: params
        expect(response.status).to eq 200
        ama_hearing.reload
        expect(ama_hearing.advance_on_docket_motion.person.id).to eq ama_hearing.appeal.appellant.id
        expect(ama_hearing.advance_on_docket_motion.reason).to eq Constants.AOD_REASONS.age
        expect(ama_hearing.advance_on_docket_motion.granted).to eq true
      end
    end

    context "when updating hearing location" do
      it "should return error if facility_id is not provided" do
        params = {
          id: ama_hearing.external_id,
          hearing: {
            notes: "Test",
            hearing_location_attributes: {
              distance: 50,
              address: "fake address",
              city: "fake city"
            }
          }
        }
        patch :update, as: :json, params: params
        expect(response.status).to eq 400
      end
    end

    it "should return not found" do
      patch :update, params: { id: "78484", hearing: { notes: "Test", hold_open: 30, transcript_requested: false } }
      expect(response.status).to eq 404
    end
  end

  describe "#show" do
    let!(:hearing) { create(:hearing, :with_tasks, scheduled_time: "8:30AM") }
    let(:expected_time_zone) { "America/New_York" }
    # for "America/New_York", "-04:00" or "-05:00" depending on daylight savings time
    let(:utc_offset) do
      hours, minutes = Time.zone.now.in_time_zone(expected_time_zone).utc_offset.divmod(60)[0].divmod(60)
      hour_string = (hours < 0) ? format("%<hours>03i", hours: hours) : format("+%<hours>02i", hours: hours)
      "#{hour_string}:#{format('%<minutes>02i', minutes: minutes)}"
    end

    subject do
      get :show, as: :json, params: { id: hearing.external_id }
    end

    it "returns hearing details" do
      expect(subject.status).to eq 200
    end

    shared_examples_for "returns the correct hearing time in EST" do |expected_time|
      it "returns the correct hearing time in EST", :aggregate_failures do
        body = JSON.parse(subject.body)

        expect(body["data"]["regional_office_timezone"]).to eq(expected_time_zone)
        expect(body["data"]["scheduled_time_string"]).to eq(expected_time)
        expect(body["data"]["scheduled_for"]).to eq(
          "#{hearing.hearing_day.scheduled_for}T#{expected_time}:00.000#{utc_offset}"
        )
      end
    end

    it_should_behave_like "returns the correct hearing time in EST", "08:30"

    context "for user on west coast" do
      let!(:user) do
        User.authenticate!(
          user: create(:user, :judge, selected_regional_office: oakland_ro_pacific, station_id: 343)
        )
      end

      it_should_behave_like "returns the correct hearing time in EST", "05:30"
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
            params: { appeal_id: appeal.external_id, regional_office: baltimore_ro_eastern }

        expect(response.status).to eq 200
      end
    end

    context "for legacy appeals" do
      let!(:vacols_case) { create(:case) }
      let!(:legacy_appeal) { create(:legacy_appeal, :with_veteran_address, vacols_case: vacols_case) }

      it "returns an address" do
        get :find_closest_hearing_locations,
            as: :json,
            params: { appeal_id: legacy_appeal.external_id, regional_office: baltimore_ro_eastern }

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
            params: { appeal_id: appeal.external_id, regional_office: baltimore_ro_eastern }

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
            params: { appeal_id: appeal.external_id, regional_office: baltimore_ro_eastern }

        expect(response.status).to eq 500
        expect(JSON.parse(response.body).dig("errors").first.dig("detail"))
          .to eq("An unexpected error occured when attempting to map veteran.")
      end
    end
  end
end

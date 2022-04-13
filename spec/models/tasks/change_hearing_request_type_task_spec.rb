# frozen_string_literal: true
SingleCov.covered!
describe ChangeHearingRequestTypeTask do
  let(:task) { create(:change_hearing_request_type_task, :assigned) }
  let(:user) { create(:user, roles: ["Edit HearSched"]) }
  let(:vso_user) { create(:user, roles: ["VSO"]) }

  describe "#update_from_params" do
    subject { task.update_from_params(payload, user) }

    context "when payload has cancelled status" do
      let(:payload) do
        {
          status: Constants.TASK_STATUSES.cancelled
        }
      end

      it "cancels the task" do
        expect { subject }.to(
          change { task.reload.status }
            .from(Constants.TASK_STATUSES.assigned)
            .to(Constants.TASK_STATUSES.cancelled)
        )
      end

      context "there's a full task tree" do
        let(:loc_schedule_hearing) { LegacyAppeal::LOCATION_CODES[:schedule_hearing] }
        let(:vacols_case) { create(:case, :travel_board_hearing, bfcurloc: loc_schedule_hearing) }
        let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
        let(:root_task) { create(:root_task, appeal: appeal) }
        let(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task) }
        let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task) }
        let!(:task) { create(:change_hearing_request_type_task, appeal: appeal, parent: schedule_hearing_task) }

        it "cancels the hearing task tree without triggering callbacks" do
          expect(hearing_task).to_not receive(:when_child_task_completed)

          subject

          expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(schedule_hearing_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(hearing_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(vacols_case.reload.bfcurloc).to eq(loc_schedule_hearing)
        end

        context "the request type is being changed" do
          context "to video from central" do
            let(:vacols_case) { create(:case, :central_office_hearing) }
            let(:payload) do
              {
                "status": "completed",
                "business_payloads": {
                  "values": {
                    "changed_hearing_request_type": "V",
                    "closest_regional_office": nil,
                  }
                }
              }
            end

            it "updates the hearing request type in VACOLS" do
              expect(vacols_case.bfhr).to eq "1"
              expect(vacols_case.bfdocind).to eq nil

              subject

              expect(vacols_case.reload.bfhr).to eq "2"
              expect(vacols_case.reload.bfdocind).to eq "V"
            end
          end

          context "to central from video" do
            let(:vacols_case) { create(:case, :video_hearing_requested) }
            let(:payload) do
              {
                "status": "completed",
                "business_payloads": {
                  "values": {
                    "changed_hearing_request_type": "C",
                    "closest_regional_office": "C"
                  }
                }
              }
            end

            it "updates the hearing request type in VACOLS" do
              expect(vacols_case.bfhr).to eq "2"
              expect(vacols_case.bfdocind).to eq "V"

              subject

              expect(vacols_case.reload.bfhr).to eq "1"
              expect(vacols_case.reload.bfdocind).to eq nil
            end
          end

          context "to virtual from video" do
            let(:vacols_case) { create(:case, :video_hearing_requested) }
            let(:payload) do
              {
                "status": "completed",
                "business_payloads": {
                  "values": {
                    "changed_hearing_request_type": "R",
                    "closest_regional_office": "RO17"
                  }
                }
              }
            end

            it "does not change the hearing request type in VACOLS" do
              expect(vacols_case.bfhr).to eq "2"
              expect(vacols_case.bfdocind).to eq "V"

              subject

              expect(vacols_case.reload.bfhr).to eq "2"
              expect(vacols_case.reload.bfdocind).to eq "V"
            end
          end
        end
      end
    end
  end
  # section for testing update_from_params as a VSO user
  describe "#update_from_params as a VSO user" do
    subject { task.update_from_params(payload, vso_user) }

    let(:loc_schedule_hearing) { LegacyAppeal::LOCATION_CODES[:schedule_hearing] }
    let(:vacols_case) { create(:case, :travel_board_hearing, bfcurloc: loc_schedule_hearing) }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:root_task) { create(:root_task, appeal: legacy_appeal) }
    let(:hearing_task) { create(:hearing_task, appeal: legacy_appeal, parent: root_task) }
    let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: legacy_appeal, parent: hearing_task) }
    let!(:task) { create(:change_hearing_request_type_task, appeal: legacy_appeal, parent: schedule_hearing_task) }
    #------LEGACY APPEAL ^-------------AMA APPEAL v------------------------------------------------------
    let!(:appeal) { create(:appeal) }
    let(:root_task1) { create(:root_task, appeal: appeal) }
    let(:hearing_task1) { create(:hearing_task, appeal: appeal, parent: root_task1) }
    let(:schedule_hearing_task1) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task1) }
    let!(:task1) { create(:change_hearing_request_type_task, appeal: appeal, parent: schedule_hearing_task1) }

    context "Legacy a VSO user tries to convert an appellant to virtual from video" do
      let(:vacols_case) { create(:case, :video_hearing_requested) }
      let(:payload) do
        {
          "status": "completed",
          "business_payloads": {
            "values": {
              "changed_hearing_request_type": "R",
              "closest_regional_office": "RO17", 
              "email_recipients": {
                "appellant_tz": "America/New_York",
                "representative_tz": "America/Los_Angeles",
                "appellant_email": "asjkfjdkjfd@va.gov"
              }
            }
          }
        }
      end

      it "creates the email recipients with the correct info (Legacy)" do
        subject

        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: legacy_appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: legacy_appeal)

        expect(new_her_a.email_address).to_eq("asjkfjdkjfd@va.gov")
        expect(new_her_a.timezone).to_eq("America/New_York")
        expect(new_her_r.timezone).to_eq("America/Los_Angeles")
      end
    end
    context "AMA a VSO user tries to convert an appellant to virtual from video" do
      let(:vacols_case) { create(:case, :video_hearing_requested) }
      let(:payload) do
        {
          "status": "completed",
          "business_payloads": {
            "values": {
              "changed_hearing_request_type": "R",
              "closest_regional_office": "RO17", 
              "email_recipients": {
                "appellant_tz": "America/New_York",
                "representative_tz": "America/Los_Angeles",
                "appellant_email": "asjkfjdkjfd@va.gov"
              }
            }
          }
        }
      end

      it "creates the email recipients with the correct info(AMA)" do
        subject

        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: appeal)

        expect(new_her_a.email_address).to_eq("asjkfjdkjfd@va.gov")
        expect(new_her_a.timezone).to_eq("America/New_York")
        expect(new_her_r.timezone).to_eq("America/Los_Angeles")
      end
    end
  end
end

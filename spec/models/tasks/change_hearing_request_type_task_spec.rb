# frozen_string_literal: true

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
                    "closest_regional_office": nil
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
  describe "#update_from_params as a VSO user legacy" do
    subject { task.update_from_params(payload, vso_user) }
    let(:loc_schedule_hearing) { LegacyAppeal::LOCATION_CODES[:schedule_hearing] }
    let(:vacols_case) { create(:case, :travel_board_hearing, bfcurloc: loc_schedule_hearing) }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:root_task) { create(:root_task, appeal: legacy_appeal) }
    let(:hearing_task) { create(:hearing_task, appeal: legacy_appeal, parent: root_task) }
    let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: legacy_appeal, parent: hearing_task) }
    let!(:task) { create(:change_hearing_request_type_task, appeal: legacy_appeal, parent: schedule_hearing_task) }

    context "a VSO user tries to convert an appellant to virtual from video" do
      let(:payload) do
        {
          "status": "completed",
          "business_payloads": {
            "values": {
              "changed_hearing_request_type": "R",
              "closest_regional_office": "RO17",
              "email_recipients": {
                "appellant_tz": "America/Los_Angeles",
                "representative_tz": "America/Los_Angeles",
                "appellant_email": "asjkfjdkjfd@va.gov",
                "representative_email": "sejfiejfiej@va.gov"
              }
            }
          }
        }
      end
      it "creates the email recipients with the correct info (Legacy)" do
        subject
        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: legacy_appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: legacy_appeal)
        expect(new_her_a.email_address).to eq("asjkfjdkjfd@va.gov")
        expect(new_her_r.email_address).to eq("sejfiejfiej@va.gov")
        expect(new_her_a.timezone).to eq("America/Los_Angeles")
        expect(new_her_r.timezone).to eq("America/Los_Angeles")
      end

      it "checks to see if a HearingEmailRecipient currently exists" do
        subject
        # variables for HearingEmailRecipient :id, :timezone, :email_address, :type, :appeal_id, :appeal_type
        # create existing appellant and recipient with different information
        existing_her_a = AppellantHearingEmailRecipient.create!(
          appeal: legacy_appeal,
          timezone: "America/New_York",
          email_address: "old_email_address@va.gov"
        )
        existing_her_r = RepresentativeHearingEmailRecipient.create!(
          appeal: legacy_appeal,
          timezone: "America/New_York",
          email_address: "old_rep_email_address@va.gov"
        )

        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: legacy_appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: legacy_appeal)

        expect(new_her_a).to eq(existing_her_a)
        expect(new_her_r).to eq(existing_her_r)
      end

      it "checks to see if a HearingEmailRecipient currently exists and updates it" do
        # variables for HearingEmailRecipient :id, :timezone, :email_address, :type, :appeal_id, :appeal_type
        # create existing appellant and recipient with different information
        existing_her_a = AppellantHearingEmailRecipient.create!(
          appeal: legacy_appeal,
          timezone: "America/New_York",
          email_address: "old_email_address@va.gov"
        )
        existing_her_r = RepresentativeHearingEmailRecipient.create!(
          appeal: legacy_appeal,
          timezone: "America/New_York",
          email_address: "old_rep_email_address@va.gov"
        )
        subject
        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: legacy_appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: legacy_appeal)

        # expect the hearing email recipients to be updated from the payload
        expect(new_her_a.email_address).to eq("asjkfjdkjfd@va.gov")
        expect(new_her_r.email_address).to eq("sejfiejfiej@va.gov")
        expect(new_her_a.timezone).to eq("America/Los_Angeles")
        expect(new_her_r.timezone).to eq("America/Los_Angeles")
        expect(new_her_a.email_address).not_to eq(existing_her_a.email_address)
        expect(new_her_r.timezone).not_to eq(existing_her_r.timezone)
      end
    end
  end
  describe "#update_from_params as a VSO user AMA" do
    subject { task.update_from_params(payload, vso_user) }
    let!(:appeal) { create(:appeal) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task) }
    let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task) }
    let!(:task) { create(:change_hearing_request_type_task, appeal: appeal, parent: schedule_hearing_task) }
    context "a VSO user tries to convert an appellant to virtual from video" do
      let(:payload) do
        {
          "status": "completed",
          "business_payloads": {
            "values": {
              "changed_hearing_request_type": "R",
              "closest_regional_office": "RO17",
              "email_recipients": {
                "appellant_tz": "America/Los_Angeles",
                "representative_tz": "America/Los_Angeles",
                "appellant_email": "gdkfkdjfkdjf@va.gov",
                "representative_email": "erueiruierufe@va.gov"
              }
            }
          }
        }
      end

      it "creates the email recipients with the correct info(AMA)" do
        subject

        new_her1_a = AppellantHearingEmailRecipient.find_by(appeal: appeal)
        new_her1_r = RepresentativeHearingEmailRecipient.find_by(appeal: appeal)
        expect(new_her1_a.email_address).to eq("gdkfkdjfkdjf@va.gov")
        expect(new_her1_r.email_address).to eq("erueiruierufe@va.gov")
        expect(new_her1_a.timezone).to eq("America/Los_Angeles")
        expect(new_her1_r.timezone).to eq("America/Los_Angeles")
      end
      it "checks to see if a HearingEmailRecipient currently exists" do
        subject
        # variables for HearingEmailRecipient :id, :timezone, :email_address, :type, :appeal_id, :appeal_type
        # create existing appellant and recipient with different information
        existing_her_a = AppellantHearingEmailRecipient.create!(
          appeal: appeal,
          timezone: "America/New_York",
          email_address: "old_email_address@va.gov"
        )
        existing_her_r = RepresentativeHearingEmailRecipient.create!(
          appeal: appeal,
          timezone: "America/New_York",
          email_address: "old_rep_email_address@va.gov"
        )

        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: appeal)

        expect(new_her_a).to eq(existing_her_a)
        expect(new_her_r).to eq(existing_her_r)
      end

      it "checks to see if a HearingEmailRecipient currently exists and updates it" do
        # variables for HearingEmailRecipient :id, :timezone, :email_address, :type, :appeal_id, :appeal_type
        # create existing appellant and recipient with different information
        existing_her_a = AppellantHearingEmailRecipient.create!(
          appeal: appeal,
          timezone: "America/New_York",
          email_address: "old_email_address@va.gov"
        )
        existing_her_r = RepresentativeHearingEmailRecipient.create!(
          appeal: appeal,
          timezone: "America/New_York",
          email_address: "old_rep_email_address@va.gov"
        )
        subject
        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: appeal)

        # expect the hearing email recipients to be updated from the payload
        expect(new_her_a.email_address).to eq("gdkfkdjfkdjf@va.gov")
        expect(new_her_r.email_address).to eq("erueiruierufe@va.gov")
        expect(new_her_a.timezone).to eq("America/Los_Angeles")
        expect(new_her_r.timezone).to eq("America/Los_Angeles")
        expect(new_her_a.email_address).not_to eq(existing_her_a.email_address)
        expect(new_her_r.timezone).not_to eq(existing_her_r.timezone)
      end
    end
  end
end

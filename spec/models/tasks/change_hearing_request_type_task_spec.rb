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
        # variables for HearingEmailRecipient :id, :timezone, :email_address, :type, :appeal_id, :appeal_type
        # create existing appellant and recipient with payload information
        existing_her_a = AppellantHearingEmailRecipient.create!(
          appeal: legacy_appeal,
          timezone: payload[:business_payloads][:values][:email_recipients][:appellant_tz],
          email_address: payload[:business_payloads][:values][:email_recipients][:appellant_email]
        )
        existing_her_r = RepresentativeHearingEmailRecipient.create!(
          appeal: legacy_appeal,
          timezone: payload[:business_payloads][:values][:email_recipients][:representative_tz],
          email_address: payload[:business_payloads][:values][:email_recipients][:representative_email]
        )

        subject

        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: legacy_appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: legacy_appeal)

        # verify that the object references are the same
        expect(new_her_a).to eq(existing_her_a)
        expect(new_her_r).to eq(existing_her_r)
        # verify that no changes were made to the objects
        expect(new_her_a.email_address).to eq(existing_her_a.email_address)
        expect(new_her_r.email_address).to eq(existing_her_r.email_address)
        expect(new_her_a.timezone).to eq(existing_her_a.timezone)
        expect(new_her_r.timezone).to eq(existing_her_r.timezone)
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
        # variables for HearingEmailRecipient :id, :timezone, :email_address, :type, :appeal_id, :appeal_type
        # create existing appellant and recipient with payload information
        existing_her_a = AppellantHearingEmailRecipient.create!(
          appeal: appeal,
          timezone: payload[:business_payloads][:values][:email_recipients][:appellant_tz],
          email_address: payload[:business_payloads][:values][:email_recipients][:appellant_email]
        )
        existing_her_r = RepresentativeHearingEmailRecipient.create!(
          appeal: appeal,
          timezone: payload[:business_payloads][:values][:email_recipients][:representative_tz],
          email_address: payload[:business_payloads][:values][:email_recipients][:representative_email]
        )

        subject

        new_her_a = AppellantHearingEmailRecipient.find_by(appeal: appeal)
        new_her_r = RepresentativeHearingEmailRecipient.find_by(appeal: appeal)

        # verify that the object references are the same
        expect(new_her_a).to eq(existing_her_a)
        expect(new_her_r).to eq(existing_her_r)
        # verify that no changes were made to the objects
        expect(new_her_a.email_address).to eq(existing_her_a.email_address)
        expect(new_her_r.email_address).to eq(existing_her_r.email_address)
        expect(new_her_a.timezone).to eq(existing_her_a.timezone)
        expect(new_her_r.timezone).to eq(existing_her_r.timezone)
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

  # Skipped because this no longer works with new "split" association definitions.
  #   Use a scoped `preload` instead (eg. `ChangeHearingRequestTypeTask.legacy.preload(:appeal)`).
  xdescribe "eager loading Legacy appeals with `includes`" do
    subject { described_class.open.includes(:legacy_appeal) }

    let!(:_legacy_task) { create(:task) }
    let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }
    let!(:_higher_level_review_task) { create(:higher_level_review_task) }

    context "when there are no ChangeHearingRequestTypeTasks" do
      it { should be_none }
    end

    context "when there are ChangeHearingRequestTypeTasks" do
      let!(:change_hearing_request_type_tasks) do
        create_list(:change_hearing_request_type_task, 10, :assigned,
                    appeal: create(:legacy_appeal, vacols_id: rand(100_000..999_999).to_s))
      end

      it { should contain_exactly(*change_hearing_request_type_tasks) }

      it "prevents N+1 queries" do
        QuerySubscriber.new.tap do |subscriber|
          subscriber.track { subject.map { |task| task.legacy_appeal.id } }
          expect(subscriber.queries.count).to eq 2
        end
      end
    end
  end

  describe "eager loading Legacy appeals with `preload`" do
    subject { described_class.open.legacy.preload(:appeal) }

    let!(:_legacy_task) { create(:task) }
    let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }
    let!(:_higher_level_review_task) { create(:higher_level_review_task) }

    context "when there are no ChangeHearingRequestTypeTasks" do
      it { should be_none }
    end

    context "when there are ChangeHearingRequestTypeTasks" do
      let!(:change_hearing_request_type_tasks) do
        create_list(:change_hearing_request_type_task, 10, :assigned,
                    appeal: create(:legacy_appeal, vacols_id: rand(100_000..999_999).to_s))
      end

      it { should contain_exactly(*change_hearing_request_type_tasks) }

      it "prevents N+1 queries" do
        QuerySubscriber.new.tap do |subscriber|
          subscriber.track { subject.map { |task| task.appeal.id } }
          expect(subscriber.queries.count).to eq 2
        end
      end
    end
  end
end

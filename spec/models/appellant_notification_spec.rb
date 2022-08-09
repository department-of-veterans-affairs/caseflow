# frozen_string_literal: true

require "appellant_notification.rb"

describe AppellantNotification do
  describe "class methods" do
    describe "self.handle_errors" do
      let(:appeal) { create(:appeal, number_of_claimants: 1) }

      context "if appeal is nil" do
        let(:empty_appeal) {}
        it "reports the error" do
          expect { AppellantNotification.handle_errors(empty_appeal) }.to raise_error(
            AppellantNotification::NoAppealError
          )
        end
      end

      context "with no claimant listed" do
        let(:appeal) { create(:appeal, number_of_claimants: 0) }
        it "returns error message" do
          expect(AppellantNotification.handle_errors(appeal)).to eq(
            AppellantNotification::NoClaimantError.new(appeal.id).message
          )
        end
      end

      context "with no participant_id listed" do
        let(:claimant) { create(:claimant, participant_id: "") }
        let(:appeal) { create(:appeal) }
        before do
          appeal.claimants = [claimant]
        end
        it "returns error message" do
          expect(AppellantNotification.handle_errors(appeal)).to eq(
            AppellantNotification::NoParticipantIdError.new(appeal.id).message
          )
        end
      end

      context "with no errors" do
        it "doesn't raise" do
          expect(AppellantNotification.handle_errors(appeal)).to eq "Success"
        end
      end
    end

    describe "self.create_payload" do
      let(:good_appeal) { create(:appeal, number_of_claimants: 1) }
      let(:bad_appeal) { create(:appeal) }
      let(:bad_claimant) { create(:claimant, participant_id: "") }
      let(:template_name) { "test" }

      context "creates a payload with no exceptions" do
        it "has a status value of success" do
          expect(
            AppellantNotification.create_payload(good_appeal, template_name)[:message_attributes][:status][:value]
          ).to eq "Success"
        end
      end

      context "creates a payload with errors" do
        before do
          bad_appeal.claimants = [bad_claimant]
        end
        it "does not have a success status" do
          expect(
            AppellantNotification.create_payload(bad_appeal, template_name)[:message_attributes][:status][:value]
          ).not_to eq "Success"
        end
      end
    end

    describe "self.notify_appellant" do
      let(:appeal) { create(:appeal, number_of_claimants: 1) }
      let(:template_name) { "test" }
      context "sends message to shoryuken" do
        it "sends the payload" do
          queue = double("queue")
          expect(queue).to receive(:send_message).with(AppellantNotification.create_payload(appeal, template_name))
          AppellantNotification.notify_appellant(appeal, template_name, queue)
        end
      end
    end
  end
end

describe AppellantNotification do
  describe AppealDocketed do
    describe "docket_appeal" do
      let(:appeal) { create(:appeal, :with_pre_docket_task) }
      let(:template_name) { "AppealDocketed" }
      let(:pre_docket_task) { PreDocketTask.find_by(appeal: appeal) }
      # before do
      #   PreDocketTask.prepend(AppellantNotification::AppealDocketed)
      # end
      it "will notify appellant that Predocketed Appeal is docketed" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        pre_docket_task.docket_appeal
      end
    end

    describe "create_tasks_on_intake_success!" do
      let(:appeal) { create(:appeal) }
      let(:template_name) { "AppealDocketed" }
      # before do
      #   Appeal.prepend(AppellantNotification::AppealDocketed)
      # end
      it "will notify appellant that appeal is docketed on successful intake" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        appeal.create_tasks_on_intake_success!
      end
    end
  end

  describe AppealDecisionMailed do
    describe "Legacy Appeal Decision Mailed" do
      let(:legacy_appeal) { create(:legacy_appeal, :with_root_task) }
      let(:params) do
        {
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:template_name) { "AppealDecisionMailed" }
      let(:dispatch) { LegacyAppealDispatch.new(appeal: legacy_appeal, params: params) }
      # before do
      #   LegacyAppealDispatch.prepend(AppellantNotification::AppealDecisionMailed)
      # end
      it "Will notify appellant that the legacy appeal decision has been mailed" do
        expect(AppellantNotification).to receive(:notify_appellant).with(legacy_appeal, template_name)
        dispatch.complete_root_task!
      end
    end

    describe "AMA Appeal Decision Mailed" do
      let(:appeal) { create(:appeal, :with_root_task) }
      let(:params) do
        {
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:user) { create(:user) }
      let(:template_name) { "AppealDecisionMailed" }
      let(:dispatch) { AmaAppealDispatch.new(appeal: appeal, params: params, user: user) }
      # before do
      #   AmaAppealDispatch.prepend(AppellantNotification::AppealDecisionMailed)
      # end
      it "Will notify appellant that the legacy appeal decision has been mailed" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        dispatch.complete_dispatch_root_task!
      end
    end
  end

  describe HearingScheduled do
    describe "#create_hearing" do
      let(:appeal_hearing) { create(:appeal, :with_schedule_hearing_tasks) }
      let(:template_name) { "HearingScheduled" }
      let(:schedule_hearing_task) { ScheduleHearingTask.find_by(appeal: appeal_hearing) }
      let(:task_values) do
        {
          appeal: appeal_hearing,
          hearing_day_id: create(:hearing_day).id,
          hearing_location_attributes: {},
          scheduled_time_string: "11:30am",
          notes: "none"
        }
      end
      # before do
      #   ScheduleHearingTask.prepend(AppellantNotification::HearingScheduled)
      # end
      it "will notify appellant when a hearing is scheduled" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal_hearing, template_name)
        schedule_hearing_task.create_hearing(task_values)
      end
    end
  end

  describe HearingPostponed do
    describe "#postpone!" do
      # let(:appeal_hearing) {create(:appeal, :tied_to_judge)}
      let(:template_name) { "HearingPostponed" }
      let(:hearing_disposition_task) { create(:assign_hearing_disposition_task) }
      # before do
      #   AssignHearingDispositionTask.prepend(AppellantNotification::HearingPostponed)
      # end
      it "will notify appellant when a hearing is postponed" do
        appeal_hearing = hearing_disposition_task.appeal
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal_hearing, template_name)
        hearing_disposition_task.postpone!
      end

      # not working yet
    end
  end
end

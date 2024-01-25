# frozen_string_literal: true

describe ChangeHearingRequestTypeTaskCancellationJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    it "assigns RequestStore[:current_user]" do
      expect { perform }.to change { RequestStore[:current_user] }.from(nil).to(User.system_user)
    end

    context "when there are no ChangeHearingRequestTypeTasks" do
      it "appends appropriate logs to application logs" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)

        expect(rails_logger).to receive(:info).with("Attempting to remediate 0 Change Hearing Request Type Tasks")

        perform
      end

      it "returns empty Array" do
        expect(perform).to eq([])
      end
    end

    context "when there are ChangeHearingRequestTypeTasks" do
      let!(:chrt_assigned_with_ama_appeal) { create(:change_hearing_request_type_task, :assigned, appeal: ama_appeal ) }
      let!(:chrt_assigned_with_legacy_appeal) { create(:change_hearing_request_type_task, :assigned, appeal: legacy_appeal ) }
      let!(:chrt_in_progress_with_legacy_appeal) { create(:change_hearing_request_type_task, :in_progress, appeal: legacy_appeal ) }
      let!(:chrt_on_hold_with_legacy_appeal) { create(:change_hearing_request_type_task, :on_hold, appeal: legacy_appeal ) }
      let!(:chrt_completed_with_legacy_appeal) { create(:change_hearing_request_type_task, :completed, appeal: legacy_appeal ) }
      let!(:chrt_cancelled_with_legacy_appeal) { create(:change_hearing_request_type_task, :cancelled, appeal: legacy_appeal ) }
      let!(:non_chrt_assigned_with_legacy_appeal) { create(:task, :assigned, appeal: legacy_appeal ) }

      let(:ama_appeal) { create(:appeal) }
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      let(:location) { legacy_appeal.location_code.to_s }
      let(:vacols_id) { legacy_appeal.vacols_id.to_s }

      it "only updates open ChangeHearingRequestTypeTasks belonging to Legacy Appeals" do
        RSpec::Matchers.define_negated_matcher :not_change, :change

        expect { perform }
          .to change { chrt_assigned_with_legacy_appeal.reload.status }.to("cancelled")
          .and change { chrt_in_progress_with_legacy_appeal.reload.status }.to("cancelled")
          .and change { chrt_on_hold_with_legacy_appeal.reload.status }.to("cancelled")
          .and not_change { chrt_assigned_with_ama_appeal }
          .and not_change { chrt_completed_with_legacy_appeal }
          .and not_change { chrt_cancelled_with_legacy_appeal }
          .and not_change { non_chrt_assigned_with_legacy_appeal }
      end

      it "appends appropriate logs to application logs" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)
        allow(rails_logger).to receive(:info).with(a_string_matching(/STARTED/)).at_least(:once).ordered
        allow(rails_logger).to receive(:info).with(a_string_matching(/FINISHED/)).at_least(:once).ordered

        expect(rails_logger).to receive(:info).with("Attempting to remediate 3 Change Hearing Request Type Tasks").at_least(:once).ordered
        expect(rails_logger).to receive(:info).with("Closing CHRT on Legacy Appeal: #{vacols_id} at location #{location}").at_least(:once).ordered
        expect(rails_logger).to receive(:info).with("Appeal:#{vacols_id}CHRT closed").at_least(:once).ordered

        perform
      end

      it "returns Array of ChangeHearingRequestTypeTasks to have been updated" do
        expect(perform).to contain_exactly(
          chrt_assigned_with_legacy_appeal,
          chrt_in_progress_with_legacy_appeal,
          chrt_on_hold_with_legacy_appeal
        )
      end
    end

    context "when an error occurs while updating a task" do
      let!(:_task) { create(:change_hearing_request_type_task, :assigned, appeal: legacy_appeal ) }

      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      let(:location) { legacy_appeal.location_code.to_s }
      let(:vacols_id) { legacy_appeal.vacols_id.to_s }

      before do
        expect_any_instance_of(ChangeHearingRequestTypeTask).to receive(:update_from_params).and_raise(StandardError)
      end

      it "logs error" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)
        allow(rails_logger).to receive(:info).with(a_string_matching(/STARTED/)).ordered
        allow(rails_logger).to receive(:info).with(a_string_matching(/FINISHED/)).ordered

        expect(rails_logger).to receive(:info).with("Attempting to remediate 1 Change Hearing Request Type Tasks").ordered
        expect(rails_logger).to receive(:info).with("Closing CHRT on Legacy Appeal: #{vacols_id} at location #{location}").ordered
        expect(rails_logger).to receive(:info).with(a_string_matching(/Task:.*Failed top be remdiated/)).ordered

        perform
      end
    end
  end
end

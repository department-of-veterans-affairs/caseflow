# frozen_string_literal: true

require "rails_helper"

describe HearingDispositionChangeJob do
  describe ".modify_task_by_dispisition" do
    def create_disposition_task_ancestry(disposition: nil, scheduled_for: nil)
      appeal = FactoryBot.create(:appeal)
      root_task = FactoryBot.create(:root_task, appeal: appeal)
      distribution_task = FactoryBot.create(:distribution_task, appeal: appeal, parent: root_task)
      parent_hearing_task = FactoryBot.create(:hearing_task, appeal: appeal, parent: distribution_task)

      hearing = FactoryBot.create(:hearing, appeal: appeal, disposition: disposition)
      if scheduled_for
        hearing_day = FactoryBot.create(:hearing_day, scheduled_for: scheduled_for)
        hearing.update!(hearing_day: hearing_day)
      end

      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent_hearing_task)
      DispositionTask.create!(appeal: appeal, parent: parent_hearing_task, assigned_to: Bva.singleton)
    end

    subject { HearingDispositionChangeJob.new.modify_task_by_dispisition(task) }

    context "when hearing has a disposition" do
      let(:task) { create_disposition_task_ancestry(disposition: disposition) }

      context "when disposition is held" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.held }
        it "returns a label matching the hearing disposition and not change the task until #9540 is merged" do
          attributes_before = task.attributes
          expect(subject).to eq(disposition)
          expect(task.attributes).to eq(attributes_before)
        end
      end

      context "when disposition is cancelled" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }
        it "returns a label matching the hearing disposition and call DispositionTask.cancel!" do
          expect(task).to receive(:cancel!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when disposition is postponed" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
        it "returns a label matching the hearing disposition and not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(disposition)
          expect(task.attributes).to eq(attributes_before)
        end
      end

      context "when disposition is no_show" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.no_show }
        it "returns a label matching the hearing disposition and call DispositionTask.mark_no_show!" do
          expect(task).to receive(:mark_no_show!).exactly(1).times
          expect(subject).to eq(disposition)
        end
      end

      context "when the disposition is not an expected disposition" do
        let(:disposition) { "FAKE_DISPOSITION" }
        it "returns a label indicating that the hearing disposition is unknown and not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(:unknown_disposition)
          expect(task.attributes).to eq(attributes_before)
        end
      end
    end

    context "when hearing has no disposition" do
      let(:task) { create_disposition_task_ancestry(disposition: nil, scheduled_for: scheduled_for) }

      context "when hearing was scheduled to take place more than 2 days ago" do
        let(:scheduled_for) { 3.days.ago }

        it "returns a label indicating that the hearing is stale and does not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(:stale)
          expect(task.attributes).to eq(attributes_before)
        end
      end

      context "when hearing was scheduled to take place less than 2 days ago" do
        let(:scheduled_for) { 25.hours.ago }

        it "returns a label indicating that the hearing was recently held and does not change the task" do
          attributes_before = task.attributes
          expect(subject).to eq(:between_one_and_two_days_old)
          expect(task.attributes).to eq(attributes_before)
        end
      end
    end
  end

  describe ".log_info" do
    let(:start_time) { 5.minutes.ago }
    let(:task_count_for) { {} }
    let(:error_count) { 0 }
    let(:hearing_ids) { [] }
    let(:error) { nil }

    context "when the job runs successfully" do
      it "logs and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(2).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when there is are elements in the input task_count_for hash" do
      let(:task_count_for) { { first_key: 0, second_key: 13 } }

      it "includes a sentence in the output message for each element of the hash" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Processed 0 First key hearings." \
          " Processed 13 Second key hearings." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when the job encounters a fatal error" do
      let(:err_msg) { "Example error text" }
      # Throw and then catch the error so it has a stack trace.
      let(:error) do
        fail StandardError, err_msg
      rescue StandardError => e
        e
      end

      it "logs an error message and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(3).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob failed after running for .*." \
          " Encountered errors for #{error_count} hearings. Fatal error: #{err_msg}"
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end
  end
end

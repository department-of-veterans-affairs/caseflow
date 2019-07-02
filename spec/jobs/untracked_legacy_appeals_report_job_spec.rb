# frozen_string_literal: true

require "rails_helper"

describe UntrackedLegacyAppealsReportJob do
  context "when there are LegacyAppeals charged to CASEFLOW in VACOLS without active Caseflow tasks" do
    let(:untracked_legacy_appeals) do
      Array.new(3) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    end
    let(:tracked_legacy_appeals) do
      Array.new(4) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    end

    before do
      # Set the VACOLS location code to CASEFLOW for all legacy appeals.
      [untracked_legacy_appeals, tracked_legacy_appeals].flatten.each do |appeal|
        VACOLS::Case.find_by(bfkey: appeal.vacols_id).update!(bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow])
      end

      # Only create tasks for tracked legacy appeals.
      tracked_legacy_appeals.each do |appeal|
        FactoryBot.create(:generic_task, assigned_to: FactoryBot.create(:user), appeal: appeal)
      end
    end

    describe ".legacy_appeal_ids_without_active_tasks" do
      subject { UntrackedLegacyAppealsReportJob.new.legacy_appeal_ids_without_active_tasks }

      it "returns the appeal IDs of the untracked_legacy_appeals" do
        expect(subject).to match_array(untracked_legacy_appeals.pluck(:id))
      end
    end

    describe ".perform" do
      subject { UntrackedLegacyAppealsReportJob.new.perform_now }

      it "sends a message that includes the IDs of the untracked legacy appeals to Slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, msg| slack_msg = msg }

        subject
        expect(slack_msg).to match(/#{untracked_legacy_appeals.pluck(:id).sort}/)
      end
    end
  end

  context "when all LegacyAppeals charged to CASEFLOW in VACOLS have active Caseflow tasks" do
    let(:tracked_legacy_appeals) do
      Array.new(5) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    end

    before do
      tracked_legacy_appeals.each do |appeal|
        VACOLS::Case.find_by(bfkey: appeal.vacols_id).update!(bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow])
        FactoryBot.create(:generic_task, assigned_to: FactoryBot.create(:user), appeal: appeal)
      end
    end

    describe ".legacy_appeal_ids_without_active_tasks" do
      subject { UntrackedLegacyAppealsReportJob.new.legacy_appeal_ids_without_active_tasks }

      it "returns an empty array since all legacy appeals are tracked" do
        expect(subject).to eq([])
      end
    end

    describe ".perform" do
      subject { UntrackedLegacyAppealsReportJob.new.perform_now }

      it "does not send a message to Slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, msg| slack_msg = msg }

        subject
        expect(slack_msg).to eq("")
      end
    end
  end

  describe ".send_report" do
    subject { UntrackedLegacyAppealsReportJob.new.send_report(array_ids) }

    context "when an empty array is passed to " do
      let(:array_ids) { [] }

      it "does not send a message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, msg| slack_msg = msg }

        subject
        expect(slack_msg).to eq("")
      end
    end

    context "when an array with elements is passed to " do
      let(:array_ids) { [1989, 143, 44] }

      it "the IDs are sorted and a message is sent to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, msg| slack_msg = msg }

        subject
        expect(slack_msg).to match(/#{array_ids.sort}/)
      end
    end
  end
end

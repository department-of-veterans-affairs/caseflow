# frozen_string_literal: true

require "rails_helper"

describe SyncIntakeJob do
  context ".perform" do
    it "calls Intake.close_expired_intakes!" do
      expect(RampClosedAppeal).to receive(:appeals_to_reclose).and_return([])
      expect(Intake).to receive(:close_expired_intakes!)

      SyncIntakeJob.perform_now
    end

    context "when there are RAMP VACOLS appeals that need to be reclosed" do
      let(:appeal_1) { RampClosedAppeal.new }
      let(:appeal_2) { RampClosedAppeal.new }

      before do
        allow(RampClosedAppeal).to receive(:appeals_to_reclose).and_return([appeal_1, appeal_2])
      end

      it "attempts to reclose them" do
        slack_service = instance_double(SlackService)
        expected_msg = "Intake: Successfully reclosed 2 out of 2 RAMP VACOLS appeals"

        expect(appeal_1).to receive(:reclose!)
        expect(appeal_2).to receive(:reclose!)
        expect(SlackService).to receive(:new).with(msg: expected_msg).and_return(slack_service)
        expect(slack_service).to receive(:send_notification)

        SyncIntakeJob.perform_now
      end

      context "when an error is thrown" do
        it "captures it and carries on" do
          allow(appeal_1).to receive(:reclose!).and_raise(StandardError.new)

          slack_service = instance_double(SlackService)
          expected_msg = "Intake: Successfully reclosed 1 out of 2 RAMP VACOLS appeals"

          expect(Raven).to receive(:capture_exception)
          expect(appeal_2).to receive(:reclose!)
          expect(SlackService).to receive(:new).with(msg: expected_msg).and_return(slack_service)
          expect(slack_service).to receive(:send_notification)

          SyncIntakeJob.perform_now
        end
      end
    end
  end
end

# frozen_string_literal: true

describe IncompleteDistributionsJob, :postgres do
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(SlackService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { true }
    create(:case_distribution_lever, :request_more_cases_minimum)
    create(:case_distribution_lever, :alternative_batch_size)
    create(:case_distribution_lever, :nod_adjustment)
    create(:case_distribution_lever, :batch_size_per_attorney)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
    create(:case_distribution_lever, :ama_hearing_case_affinity_days)
    create(:case_distribution_lever, :ama_hearing_case_aod_affinity_days)
    create(:case_distribution_lever, :ama_direct_review_start_distribution_prior_to_goals)
    create(:case_distribution_lever, :ama_direct_review_docket_time_goals)
    create(:case_distribution_lever, :ama_evidence_submission_docket_time_goals)
    create(:case_distribution_lever, :ama_hearing_docket_time_goals)
    create(:case_distribution_lever, :disable_legacy_non_priority)
    create(:case_distribution_lever, :disable_legacy_priority)
  end

  context ".perform" do
    subject { described_class.perform_now }

    let(:judge) do
      create(:user, :judge, :with_vacols_judge_record, css_id: "MYNAMEISJUDGE")
    end
    let!(:distribution) { Distribution.create!(judge: judge) }

    it "detects pending Distribution" do
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        message = "Restarting jobs for pending Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    it "detects stalled Distribution" do
      distribution.started_at = Time.zone.now
      distribution.started!
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        message = "Restarting jobs for stalled Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    it "detects stalled Distribution without started_at" do
      distribution.started!
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        message = "Restarting jobs for stalled Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    context "there are no incomplete Distributions" do
      it "doesn't send a slack message" do
        Timecop.travel(Time.zone.now + 30.minutes) do
          subject

          expect(slack_service).to_not have_received(:send_notification)
        end
      end
    end
  end
end

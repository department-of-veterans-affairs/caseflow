# frozen_string_literal: true

describe Distribution, :all_dbs do
  let(:new_distribution) { described_class.create!(params) }
  let(:judge) { create(:user, :with_vacols_judge_record) }
  let(:status) { "pending" }
  let(:priority_push) { false }
  let(:params) { { judge: judge, status: status, priority_push: priority_push } }

  before do
    Timecop.freeze(Time.zone.now)
    create(:case_distribution_lever, :request_more_cases_minimum)
    create(:case_distribution_lever, :batch_size_per_attorney)
    create(:case_distribution_lever, :ama_direct_review_start_distribution_prior_to_goals)
    create(:case_distribution_lever, :alternative_batch_size)
    create(:case_distribution_lever, :nod_adjustment)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
    create(:case_distribution_lever, :aoj_cavc_affinity_days)
    create(:case_distribution_lever, :aoj_aod_affinity_days)
    create(:case_distribution_lever, :aoj_affinity_days)
    create(:case_distribution_lever, :ama_hearing_case_affinity_days)
    create(:case_distribution_lever, :ama_hearing_case_aod_affinity_days)
    create(:case_distribution_lever, :ama_direct_review_docket_time_goals)
    create(:case_distribution_lever, :ama_evidence_submission_docket_time_goals)
    create(:case_distribution_lever, :ama_hearing_docket_time_goals)
    create(:case_distribution_lever, :disable_legacy_non_priority)
    create(:case_distribution_lever, :disable_legacy_priority)
  end

  context "validations" do
    let(:distribution) { described_class.new(params) }

    it "#validate_user_is_judge" do
      non_judge_user = create(:user)
      params[:judge] = non_judge_user

      expect(distribution.valid?).to be false
      expect(distribution.errors.details).to eq(judge: [{ error: :not_judge }])
    end

    context "#validate_number_of_unassigned_cases" do
      it "when distribution is not a priority push" do
        create_list(:ama_judge_assign_task, 10, assigned_to: judge)

        expect(distribution.valid?).to be false
        expect(distribution.errors.details[:judge].include?(error: :too_many_unassigned_cases)).to be true
      end

      it "when distribution is a priority push" do
        create_list(:ama_judge_assign_task, 10, assigned_to: judge)
        params[:priority_push] = true

        expect(distribution.valid?).to be true
      end
    end

    context "#validate_days_waiting_on_unassigned_cases" do
      it "when distribution is not a priority push" do
        create(:ama_judge_assign_task, assigned_at: 35.days.ago, assigned_to: judge)

        expect(distribution.valid?).to be false
        expect(distribution.errors.details[:judge].include?(error: :unassigned_cases_waiting_too_long)).to be true
      end

      it "when distribution is a priority push" do
        create(:ama_judge_assign_task, assigned_at: 35.days.ago, assigned_to: judge)
        params[:priority_push] = true

        expect(distribution.valid?).to be true
      end
    end

    context "#validate_judge_has_no_pending_distributions" do
      let(:second_distribution) { described_class.new(params) }

      before { new_distribution }

      context "when judge has a pending priority push distribution" do
        let(:priority_push) { true }

        it "judge cannot start another priority push distribution" do
          expect(second_distribution.valid?).to be false
          expect(second_distribution.errors.details[:judge].include?(error: :pending_distribution)).to be true
        end

        it "judge can start a new nonpriority distribution" do
          params[:priority_push] = false
          expect(second_distribution.valid?).to be true
        end
      end

      context "when judge has a pending nonpriority distribution" do
        it "judge cannot start another nonpriority distribution" do
          expect(second_distribution.valid?).to be false
          expect(second_distribution.errors.details[:judge].include?(error: :pending_distribution)).to be true
        end

        it "judge can start a new priority push distribution" do
          params[:priority_push] = true
          expect(second_distribution.valid?).to be true
        end
      end

      context "when distribution with status 'started' exists" do
        it "judge cannot start another distribution" do
          expect(second_distribution.valid?).to be false
          expect(second_distribution.errors.details[:judge].include?(error: :pending_distribution)).to be true
        end
      end
    end

    it "all validations pass" do
      create_list(:ama_judge_assign_task, 2, assigned_at: 5.days.ago, assigned_to: judge)

      expect(new_distribution.valid?).to be true
    end
  end

  context "#batch_size" do
    it "is set to alternative batch size if judge has no attorneys" do
      expect(new_distribution.send(:batch_size)).to eq(CaseDistributionLever.alternative_batch_size)
    end

    it "is set based on number of attorneys on team" do
      judge_team = JudgeTeam.create_for_judge(judge)
      3.times do
        team_member = create(:user)
        judge_team.add_user(team_member)
      end

      expect(new_distribution.send(:batch_size)).to eq(3 * CaseDistributionLever.batch_size_per_attorney)
    end
  end

  context "#distributed_cases_count" do
    subject { new_distribution }

    before do
      allow_any_instance_of(described_class).to receive(:distributed_cases)
        .and_return([DistributedCase.new])
    end

    it "returns 0 when the distribution is not completed" do
      expect(subject.status).to_not eq "completed"
      expect(subject.distributed_cases_count).to eq 0
    end

    it "returns the number of distributed cases when it is completed" do
      subject.distribute!
      expect(subject.status).to eq "completed"
      expect(subject.distributed_cases_count).to eq 1
    end
  end

  context "#distribute!" do
    let(:statistics) do
      {
        statistics: {
          batch_size: 0,
          direct_review_due_count: 0,
          direct_review_proportion: 0,
          evidence_submission_proportion: 0,
          hearing_proportion: 0,
          legacy_hearing_backlog_count: 0,
          legacy_proportion: 0.0,
          nonpriority_iterations: 0,
          priority_count: 0,
          total_batch_size: 0,
          sct_appeals: 0
        }
      }
    end
    let(:result_stats) do
      {
        batch_size: 0,
        info: "See related row in distribution_stats for additional stats"
      }
    end

    it "updates status and started_at" do
      expect(new_distribution).to receive(:update!)
        .with(status: :started, started_at: Time.zone.now)
        .exactly(1).times
      expect(new_distribution).to receive(:update!)
        .with(status: "completed", completed_at: Time.zone.now)
        .exactly(1).times
      expect(new_distribution).to receive(:update!)
        .with(statistics: result_stats)
        .exactly(1).times

      new_distribution.distribute!
    end

    it "updates status to error if an error is thrown and sends slack notification" do
      allow(new_distribution).to receive(:batch_size).and_raise(StandardError)
      expect_any_instance_of(SlackService).to receive(:send_notification).exactly(1).times

      expect { new_distribution.distribute! }.to raise_error(StandardError)

      expect(new_distribution.status).to eq("error")
    end

    context "when status is an invalid value" do
      let(:status) { "invalid!" }

      it "returns nil" do
        expect(subject.distribute!).to eq(nil)
      end
    end

    context "for a requested distribution" do
      let(:priority_push) { false }

      it "calls requested_distribution" do
        expect(new_distribution).to receive(:requested_distribution)
        allow(new_distribution).to receive(:ama_statistics).and_return(statistics)
        new_distribution.distribute!
        expect(new_distribution.reload.status).to eq "completed"
      end
    end

    context "for a priority push distribution" do
      let(:priority_push) { true }

      it "calls priority_push_distribution" do
        expect(new_distribution).to receive(:priority_push_distribution)
        allow(new_distribution).to receive(:ama_statistics).and_return(statistics)
        new_distribution.distribute!
        expect(new_distribution.reload.status).to eq "completed"
      end
    end

    context "distribution lever cache" do
      it "caches lever properly" do
        expect(CaseDistributionLever).to receive(:check_distribution_lever_cache).at_least(:once).and_call_original
        new_distribution.distribute!
        expect(Rails.cache.exist?("aoj_affinity_days_distribution_lever_cache")).to be false
      end
    end
  end
end

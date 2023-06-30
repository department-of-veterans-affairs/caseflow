# frozen_string_literal: true

describe Distribution, :all_dbs do
  let(:new_distribution) { described_class.create!(params) }
  let(:judge) { create(:user, :with_vacols_judge_record) }
  let(:status) { "pending" }
  let(:priority_push) { false }
  let(:params) { { judge: judge, status: status, priority_push: priority_push } }

  before do
    Timecop.freeze(Time.zone.now)
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
      expect(new_distribution.send(:batch_size)).to eq(Constants.DISTRIBUTION.alternative_batch_size)
    end

    it "is set based on number of attorneys on team" do
      judge_team = JudgeTeam.create_for_judge(judge)
      3.times do
        team_member = create(:user)
        judge_team.add_user(team_member)
      end

      expect(new_distribution.send(:batch_size)).to eq(3 * Constants.DISTRIBUTION.batch_size_per_attorney)
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
        batch_size: 0, direct_review_due_count: 0, direct_review_proportion: 0,
        evidence_submission_proportion: 0, hearing_proportion: 0, legacy_hearing_backlog_count: 0,
        legacy_proportion: 0.0, nonpriority_iterations: 0, priority_count: 0, total_batch_size: 0,
        algorithm: "proportions"
      }
    end

    it "updates status and started_at" do
      expect(new_distribution).to receive(:update!)
        .with(status: :started, started_at: Time.zone.now)
        .exactly(1).times
      expect(new_distribution).to receive(:update!)
        .with(status: "completed", completed_at: Time.zone.now, statistics: statistics)
        .exactly(1).times

      new_distribution.distribute!
    end

    it "updates status to error if an error is thrown" do
      allow_any_instance_of(LegacyDocket).to receive(:distribute_appeals).and_raise(StandardError)

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
        allow(new_distribution).to receive(:ama_statistics).and_return({})
        new_distribution.distribute!
        expect(new_distribution.reload.status).to eq "completed"
      end
    end

    context "for a priority push distribution" do
      let(:priority_push) { true }

      it "calls priority_push_distribution" do
        expect(new_distribution).to receive(:priority_push_distribution)
        allow(new_distribution).to receive(:ama_statistics).and_return({})
        new_distribution.distribute!
        expect(new_distribution.reload.status).to eq "completed"
      end
    end
  end

  # The following are specifically testing the priority push code in the AutomaticCaseDistribution module
  # ByDocketDateDistribution tests are in their own file, by_docket_date_distribution_spec.rb
  context "priority push distributions" do
    let(:priority_push) { true }

    context "when there is no limit" do
      let(:limit) { nil }

      it "distributes priority appeals on the legacy and hearing dockets" do
        expect_any_instance_of(LegacyDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: nil, priority: true, genpop: "not_genpop", style: "push")
          .and_return([])

        expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: nil, priority: true, genpop: "not_genpop", style: "push")
          .and_return([])

        new_distribution.distribute!(limit)
      end
    end

    context "when there is a limit set" do
      let(:limit) { 10 }

      let(:stubbed_appeals) do
        {
          legacy: 5,
          direct_review: 3,
          evidence_submission: 1,
          hearing: 1
        }
      end

      it "distributes only up to the limit" do
        expect(new_distribution).to receive(:num_oldest_priority_appeals_by_docket)
          .with(limit)
          .and_return stubbed_appeals

        expect_any_instance_of(LegacyDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: 5, priority: true, style: "push")
          .and_return(create_list(:appeal, 5))

        expect_any_instance_of(DirectReviewDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: 3, priority: true, style: "push")
          .and_return(create_list(:appeal, 3))

        expect_any_instance_of(EvidenceSubmissionDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: 1, priority: true, style: "push")
          .and_return(create_list(:appeal, 1))

        expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: 1, priority: true, style: "push")
          .and_return(create_list(:appeal, 1))

        new_distribution.distribute!(limit)
      end
    end
  end

  context "requested distributions" do
    context "when priority_acd is enabled" do
      let(:limit) { 10 }
      let(:batch_size) { Constants.DISTRIBUTION.alternative_batch_size }

      before { FeatureToggle.enable!(:priority_acd) }

      it "calls distribute_appeals with bust_backlog set along with the other calls" do
        expect_any_instance_of(LegacyDocket).to receive(:distribute_nonpriority_appeals)
          .with(new_distribution, limit: batch_size, genpop: "not_genpop", bust_backlog: true, style: "request")
          .and_return([])

        expect_any_instance_of(LegacyDocket).to receive(:distribute_priority_appeals)
          .with(new_distribution, limit: batch_size, genpop: "not_genpop", style: "request")
          .and_return([])

        expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: batch_size, priority: true, genpop: "not_genpop", style: "request")
          .and_return([])

        expect_any_instance_of(LegacyDocket).to receive(:distribute_nonpriority_appeals)
          .with(new_distribution, limit: batch_size, genpop: "not_genpop", range: 0, style: "request")
          .and_return([])

        expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
          .with(new_distribution, limit: batch_size, priority: false, genpop: "not_genpop", style: "request")
          .and_return([])

        expect(new_distribution).to receive(:distribute_limited_priority_appeals_from_all_dockets)
          .with(15, style: "request")
          .and_return([])

        expect(new_distribution).to receive(:deduct_distributed_actuals_from_remaining_docket_proportions)
          .with(:legacy, :hearing)

        new_distribution.distribute!(limit)
      end
    end
  end
end

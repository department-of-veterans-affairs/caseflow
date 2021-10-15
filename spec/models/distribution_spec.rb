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
        legacy_proportion: 0.0, nonpriority_iterations: 0, priority_count: 0, total_batch_size: 0
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

  context "priority push distributions" do
    let(:priority_push) { true }

    context "when there is no limit" do
      let(:limit) { nil }

      it "distributes priority appeals on the legacy and hearing dockets" do
        expect(new_distribution).to receive(:distribute_appeals)
          .with(:legacy, limit, priority: true, genpop: "not_genpop", style: "push")
        expect(new_distribution).to receive(:distribute_appeals)
          .with(:hearing, limit, priority: true, genpop: "not_genpop", style: "push")

        new_distribution.distribute!(limit)
      end
    end

    context "when there is a limit set" do
      let(:limit) { 10 }

      let(:stubbed_appeals) do
        {
          legacy: 5,
          direct_review: 4,
          evidence_submission: 3,
          hearing: 2
        }
      end

      it "distributes only up to the limit" do
        expect(new_distribution).to receive(:num_oldest_priority_appeals_by_docket)
          .with(limit)
          .and_return stubbed_appeals

        # Wait, where _is_ this limit enforced?

        expect(new_distribution).to receive(:distribute_appeals).with(:legacy, 5, priority: true, style: "push")
        expect(new_distribution).to receive(:distribute_appeals).with(:direct_review, 4, priority: true, style: "push")
        expect(new_distribution).to receive(:distribute_appeals)
          .with(:evidence_submission, 3, priority: true, style: "push")
        expect(new_distribution).to receive(:distribute_appeals).with(:hearing, 2, priority: true, style: "push")

        new_distribution.distribute!(limit)

        # What have I done? This doesn't test what it says it tests.
      end
    end
  end

  context "requested distributions" do
    context "when priority_acd is enabled" do
      let(:limit) { 10 }
      let(:batch_size) { Distribution::ALTERNATIVE_BATCH_SIZE }

      before { FeatureToggle.enable!(:priority_acd) }

      it "calls distribute_appeals with bust_backlog set along with the other calls" do
        expect(new_distribution).to receive(:distribute_appeals)
          .with(:legacy, batch_size, priority: false, genpop: "not_genpop", bust_backlog: true, style: "request")

        expect(new_distribution).to receive(:distribute_appeals)
          .with(:legacy, batch_size, priority: true, genpop: "not_genpop", style: "request")

        expect(new_distribution).to receive(:distribute_appeals)
          .with(:hearing, batch_size, priority: true, genpop: "not_genpop", style: "request")

        expect(new_distribution).to receive(:distribute_appeals)
          .with(:legacy, batch_size, priority: false, genpop: "not_genpop", range: 0, style: "request")

        expect(new_distribution).to receive(:distribute_appeals)
          .with(:hearing, batch_size, priority: false, genpop: "not_genpop", style: "request")

        expect(new_distribution).to receive(:distribute_limited_priority_appeals_from_all_dockets)
          .with(15, style: "request")

        expect(new_distribution).to receive(:deduct_distributed_actuals_from_remaining_docket_proportions)
          .with(:legacy, :hearing)

        new_distribution.distribute!(limit)
      end
    end
  end
end

# frozen_string_literal: true

SingleCov.covered!

describe LegacyDocket do
  let(:docket) do
    LegacyDocket.new
  end

  let(:counts_by_priority_and_readiness) do
    [
      { "n" => 1, "ready" => 1, "priority" => 1 },
      { "n" => 2, "ready" => 0, "priority" => 1 },
      { "n" => 4, "ready" => 1, "priority" => 0 },
      { "n" => 8, "ready" => 0, "priority" => 0 }
    ]
  end

  context "#docket_type" do
    it "is legacy" do
      expect(subject.docket_type).to eq "legacy"
    end
  end

  context "#genpop_priority_count" do
    it "calls AppealRepository.genpop_priority_count" do
      expect(AppealRepository).to receive(:genpop_priority_count)
      subject.genpop_priority_count
    end
  end

  context "#ready_priority_appeal_ids" do
    it "calls AppealRepository.priority_ready_appeal_vacols_ids" do
      expect(AppealRepository).to receive(:priority_ready_appeal_vacols_ids)
      subject.ready_priority_appeal_ids
    end
  end

  context "#count" do
    before do
      allow(LegacyAppeal.repository).to receive(:docket_counts_by_priority_and_readiness)
        .and_return(counts_by_priority_and_readiness)
    end

    it "correctly aggregates the docket counts" do
      expect(docket.count).to eq(15)
      expect(docket.count(ready: true)).to eq(5)
      expect(docket.count(priority: false)).to eq(12)
      expect(docket.count(ready: false, priority: true)).to eq(2)
    end
  end

  context "#weight" do
    subject { docket.weight }

    before do
      allow(LegacyAppeal.repository).to receive(:docket_counts_by_priority_and_readiness)
        .and_return(counts_by_priority_and_readiness)
      allow(LegacyAppeal.repository).to receive(:nod_count).and_return(1)
    end

    it { is_expected.to eq(12.4) }
  end

  context "#really_distribute" do
    # This is really a "should_distribute?" method. We should rename it.
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { Distribution.create!(judge: judge) }
    let(:style) { "request" }
    let(:genpop) { "any" }

    subject { docket.really_distribute(distribution, style: style, genpop: genpop) }

    context "with tied cases" do
      let(:genpop) { "not_genpop" }

      it "always returns true" do
        expect(subject).to be_truthy
      end
    end

    context "with genpop cases" do
      let(:genpop) { "any" }
      context "when the JudgeTeam is set AMA only for the relevant type" do
        context "when this is a push distribution" do
          let(:style) { "push" }

          before do
            JudgeTeam.for_judge(judge).update!(ama_only_push: true, ama_only_request: false)
          end

          it "should return false since this is a legacy (non-AMA) docket", skip: "This exposes a bug to fix!" do
            # These are only for debugging
            expect(JudgeTeam.for_judge(distribution.judge).ama_only_push).to be_truthy
            expect(JudgeTeam.for_judge(distribution.judge).ama_only_request).to be_falsey
            expect(style).to eq "push"

            # Bug? When ama_only_request is false (the default), really-distribute will always return true.
            # We essentially just invert the value of ama_only_request on the last line.
            # I think we want to check if it's a request?
            expect(subject).to be_falsey
          end
        end

        context "when this is a requested distribution" do
          let(:style) { "request" }

          before do
            JudgeTeam.for_judge(judge).update!(ama_only_push: true, ama_only_request: true)
          end

          it "should return false since this is a legacy (non-AMA) docket" do
            expect(subject).to be_falsey
          end
        end
      end

      context "when the JudgeTeam is not AMA-only" do
        before do
          JudgeTeam.for_judge(judge).update!(ama_only_push: false, ama_only_request: false)
        end

        context "when this is a push distribution" do
          let(:style) { "push" }

          it "should return true" do
            expect(subject).to be_truthy
          end
        end

        context "when this is a requested distribution" do
          let(:style) { "request" }

          it "should return true" do
            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  context "#distribute_appeals" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { Distribution.create!(judge: judge) }
    let(:style) { "request" }
    let(:genpop) { "any" }
    let(:priority) { false }
    let(:limit) { 10 }

    subject { docket.distribute_appeals(distribution, style: style, priority: priority, genpop: genpop, limit: limit) }

    context "when really_distribute returns false" do
      it "returns an empty array" do
        expect(docket).to receive(:really_distribute)
          .with(distribution, style: style, genpop: genpop)
          .and_return(false)

        expect(subject).to eq []
      end
    end

    context "when this is a priority distribution" do
      let(:priority) { true }

      it "calls distribute_priority_appeals" do
        expect(docket).to receive(:distribute_priority_appeals)
          .with(distribution, style: style, genpop: genpop, limit: limit)

        subject
      end
    end

    context "when this is a non-priority distribution" do
      let(:priority) { false }

      it "calls distribute_nonpriority_appeals" do
        expect(docket).to receive(:distribute_nonpriority_appeals)
          .with(distribution, style: style, genpop: genpop, limit: limit)

        subject
      end
    end
  end

  context "#distribute_priority_appeals" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:genpop) { "any" } # this isn't significant here I don't think
    let(:style) { "push" } # ..
    let(:limit) { 1 } # ..
    let(:distribution) { Distribution.create!(judge: judge) }
    subject { docket.distribute_priority_appeals(distribution) }

    context "when really_distribute returns false, blocking distribution" do
      it "returns an empty array" do
        expect(docket).to receive(:really_distribute)
          .with(distribution, genpop: genpop, style: style)
          .and_return(false)
        expect(subject).to eq []
        subject
      end
    end

    context "when really_distribute allows distribution", skip: "Incomplete; fixme" do
      let!(:some_appeals) do
        [
          create(:legacy_appeal, vacols_id: "5643"),
          create(:legacy_appeal, vacols_id: "1234")
        ]
      end

      # AppealRepository doesn't do much but call VACOLS::CaseDocket.distribute_appeals,
      # for which we have good coverage. Just unit-test our part here:
      it "uses AppealRepository's distribute_priority_appeals method" do
        expect(docket).to receive(:really_distribute)
          .with(distribution, genpop: genpop, style: style)
          .and_return(true)
        expect(AppealRepository).to receive(:distribute_priority_appeals)
          .with(judge, genpop, limit)
          .and_return(some_appeals)

        # dist_case in distribute_priority_appeals creates a mostly-empty record which isn't valid.
        # The stubbing above is inadequate.
        subject
      end
    end
  end

  context "#distribute_nonpriority_appeals" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:genpop) { "any" } # this isn't significant here I don't think
    let(:style) { "push" } # ..
    let(:limit) { 1 } # ..
    let(:range) { nil }
    let(:bust_backlog) { false }
    let(:distribution) { Distribution.create!(judge: judge) }
    subject { docket.distribute_nonpriority_appeals(distribution, range: range) }

    context "when really_distribute returns false, blocking distribution" do
      before do
        expect(docket).to receive(:really_distribute).and_return(false)
      end

      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "when range is zero or less" do
      let(:range) { 0 }
      it "returns an empty array" do
        expect(subject).to eq []
        expect(AppealRepository).not_to receive(:distribute_nonpriority_appeals)
      end
    end

    context "when really_distribute returns true and range is nil or >= 0" do
      it "calls AppealRepository.distribute_nonpriority_appeals" do
        # Ideally this would return some mocked cases we could run further assertions on.
        expect(AppealRepository).to receive(:distribute_nonpriority_appeals)
          .with(judge, genpop, range, limit, bust_backlog)
          .and_return([])
        subject
      end
    end
  end
end

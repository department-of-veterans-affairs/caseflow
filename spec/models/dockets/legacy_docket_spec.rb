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
    let(:genpop) { "any" } # Is this a general population ("genpop") case, or is it tied to a VLJ?

    subject { docket.really_distribute(distribution, style: style, genpop: genpop)}

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

          it "should return false since this is a legacy (non-AMA) docket" do
            # These are only for debugging
            expect(JudgeTeam.for_judge(distribution.judge).ama_only_push).to be_truthy
            expect(JudgeTeam.for_judge(distribution.judge).ama_only_request).to be_falsey
            expect(style).to eq "push"

            # Bug? When ama_only_request is false (the default), really-distribute will always return true.
            # We essentially just invert the value of ama_only_request on the last line. I think we want to check if it's a request?
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
    #
  end
end

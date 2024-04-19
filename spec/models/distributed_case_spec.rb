# frozen_string_literal: true

describe DistributedCase do
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:judge) { create(:user, :judge) }
  let(:distribution) { Distribution.create!(judge: judge) }
  let(:distributed_case) do
    DistributedCase.create!(
      distribution: distribution,
      ready_at: Time.zone.now,
      docket: "foo",
      priority: false,
      case_id: "123"
    )
  end

  before { create(:case_distribution_lever, :request_more_cases_minimum) }

  describe "#rename_for_redistribution!" do
    subject { distributed_case.rename_for_redistribution! }

    it "updates the case_id" do
      subject

      expect(distributed_case.reload.case_id).to match(/123-redistributed-/)
    end

    describe "when it is an ama docket" do
      let(:distributed_case) do
        DistributedCase.create!(
          distribution: distribution,
          ready_at: Time.zone.now,
          docket: "evidence_submission",
          priority: false,
          case_id: "123",
          task: task
        )
      end

      let!(:task) do
        create(:ama_task)
      end

      before do
        distributed_case.task = task
        distributed_case.save
      end

      it "updates the case_id" do
        subject

        expect(distributed_case.reload.case_id).to match(/123-redistributed-/)
      end
    end
  end
end

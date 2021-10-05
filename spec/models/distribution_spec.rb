# frozen_string_literal: true

describe Distribution, :all_dbs do
  let(:new_distribution) { described_class.create!(params) }
  let(:judge) { create(:user, :with_vacols_judge_record) }
  let(:status) { "pending" }
  let(:priority_push) { false }
  let(:params) { {judge: judge, status: status, priority_push: priority_push} }

  before do
    Timecop.freeze(Time.zone.now)
  end

  context "#distributed_cases_count" do
    subject { new_distribution }

    before do
      allow_any_instance_of(described_class).to receive(:distributed_cases).
        and_return([DistributedCase.new])
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

  context ".pending_for_judge" do
    # This is really just pure ActiveRecord
  end

  context "#distribute!" do
    context "when status is an invalid value" do
      let(:status) { "invalid!" }

      it "returns nil" do
        expect(subject.distribute!).to eq(nil)
      end
    end

    it "updates status and started_at" do
      expect(new_distribution).to receive(:update!).exactly(2).times
      # TODO: We can't be more specific because it gets called twice when successful
      new_distribution.distribute!
    end

    # So my thinking for this and the below test is that we can test the specifics in much greater detail
    # later on in separate tests.
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
end

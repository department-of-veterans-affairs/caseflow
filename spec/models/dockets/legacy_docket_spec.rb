# frozen_string_literal: true

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
end

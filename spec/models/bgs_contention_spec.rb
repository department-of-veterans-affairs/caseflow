# frozen_string_literal: true

describe BgsContention do
  before { Timecop.freeze(Time.zone.now) }
  let(:claim_id) { "claim_id" }
  let!(:contention) { Generators::BgsContention.build(claim_id: claim_id) }
  let(:orig_source_type_code) { "APP" }
  let(:bgs_record) do
    {
      cntntn_id: "1234",
      clmnt_txt: "claimant text",
      cntntn_type_cd: "HLR",
      med_ind: "1",
      orig_source_type_cd: orig_source_type_code,
      begin_dt: 5.days.ago,
      clm_id: claim_id,
      special_issues: nil
    }
  end

  context ".fetch_all" do
    subject { described_class.fetch_all(claim_id) }

    let!(:another_contention) { Generators::BgsContention.build(claim_id: claim_id) }

    it "returns all contentions on a claim" do
      expect(subject.count).to eq(2)
    end

    context "when BGS returns an error" do
      let(:bgs_error) { BGS::ShareError.new("E") }

      it "returns nil" do
        allow_any_instance_of(Fakes::BGSService).to receive(:find_contentions_by_claim_id).and_raise(bgs_error)

        expect(subject.count).to eq(0)
      end
    end
  end

  context ".from_bgs_hash" do
    subject { described_class.from_bgs_hash(bgs_record) }

    it { is_expected.to be_a(BgsContention) }

    it do
      is_expected.to have_attributes(
        reference_id: "1234",
        text: "claimant text",
        begin_date: 5.days.ago
      )
    end
  end

  context "#exam_requested?" do
    let(:bgs_contention) { BgsContention.from_bgs_hash(bgs_record) }
    subject { bgs_contention.exam_requested? }

    it { is_expected.to be_falsey }

    context "when orig_source_type_code is equal to EXAM" do
      let!(:orig_source_type_code) { "EXAM" }

      it { is_expected.to be true }
    end
  end
end

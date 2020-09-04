# frozen_string_literal: true

describe CurrentRating do
  describe "#fetch_by_participant_id" do
    let(:bgs) { double("BGSService") }
    let(:pid) { "12345" }
    before do
      allow(BGSService).to receive(:new) { bgs }
    end

    subject { CurrentRating.fetch_by_participant_id(pid) }

    context "when participant exists" do
      let(:bgs_hash) do
        { ptcpnt_vet_id: pid }
      end
      before do
        allow(bgs).to receive(:find_current_rating_profile_by_ptcpnt_id).with(pid).and_return(bgs_hash)
      end

      it "returns a current rating object" do
        expect(subject.participant_id).to eq(pid)
      end
    end

    context "when participant doesn't exist" do
      let(:error) { BGS::ShareError.new_from_message("message", 500) }
      before do
        allow(bgs).to receive(:find_current_rating_profile_by_ptcpnt_id).with(pid).and_raise(error)
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#from_bgs_hash" do
    let(:yesterday) { DateTime.yesterday }
    let(:bgs_hash) do
      {
        ptcpnt_vet_id: "participant ID",
        prfl_dt: yesterday,
        prmlgn_dt: yesterday,
        rating_issues: [
          {
            rba_issue_id: "rating issue ID",
            decn_txt: "issue description text"
          }
        ],
        disabilities: [
          {
            decn_tn: "Service Connected",
            dis_sn: "disability ID"
          }
        ],
        associated_claims: { clm_id: "EP claim ID", bnft_clm_tc: "600PRI" }
      }
    end

    it "hydrates an object that behaves like a Rating" do
      rating = CurrentRating.from_bgs_hash(bgs_hash)
      expect(rating.participant_id).to eq("participant ID")
      expect(rating.profile_date).to eq(yesterday)
      expect(rating.promulgation_date).to eq(yesterday)
      expect(rating.issues[0].reference_id).to eq("rating issue ID")
      expect(rating.associated_end_products[0].claim_id).to eq("EP claim ID")
    end
  end
end

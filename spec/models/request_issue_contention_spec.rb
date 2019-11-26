# frozen_string_literal: true

describe RequestIssueContention, :postgres do
  let(:decision_review) { create(:higher_level_review) }
  let!(:end_product_establishment) { create(:end_product_establishment) }
  let!(:contention_reference_id) { "1234" }
  let(:edited_description) { nil }
  let(:contention_updated_at) { nil }

  let(:request_issue) do
    create(
      :request_issue,
      decision_review: decision_review,
      end_product_establishment: end_product_establishment,
      contention_reference_id: contention_reference_id,
      edited_description: edited_description,
      contention_updated_at: contention_updated_at
    )
  end

  let(:request_issue_contention) { RequestIssueContention.new(request_issue) }

  let!(:contention_id) { contention_reference_id }
  let!(:contention) do
    Generators::Contention.build(
      id: contention_id,
      claim_id: end_product_establishment.reference_id,
      text: "Left knee"
    )
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "#update_text!" do
    subject { request_issue_contention.update_text! }

    before { allow(Fakes::VBMSService).to receive(:update_contention!).and_call_original }

    let(:edited_description) { "new request issue description" }

    it "updates the contention in VBMS" do
      updated_contention = request_issue.contention
      updated_contention.text = edited_description

      expect(subject).to be true
      expect(request_issue.contention_updated_at).to be_within(1.second).of Time.zone.now
      expect(Fakes::VBMSService).to have_received(:update_contention!).with(updated_contention)
    end

    context "when the contention has already been updated in VBMS" do
      let(:contention_updated_at) { 1.day.ago }

      it { is_expected.to be_falsey }
    end
  end

  context "#remove!" do
    before { allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original }

    subject { request_issue_contention.remove! }

    it "calls VBMS with the appropriate arguments to remove the contention" do
      removed_contention = request_issue.contention

      subject

      expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(removed_contention)
      expect(request_issue.contention_removed_at).to be_within(1.second).of Time.zone.now
    end

    context "when VBMS throws an error" do
      before do
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_raise(vbms_error)
      end

      it "does not remove contentions" do
        expect { subject }.to raise_error(vbms_error)
        expect(request_issue.contention_removed_at).to be_nil
      end
    end

    context "when contention does not exist" do
      let(:contention_id) { "9999" }

      it "marks request issue as removed" do
        subject
        expect(request_issue.contention_removed_at).to_not be_nil
      end
    end
  end
end

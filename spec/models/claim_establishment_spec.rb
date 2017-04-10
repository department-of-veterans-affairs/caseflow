describe ClaimEstablishment do
  let(:appeal_remand) do
    Generators::Appeal.build(vacols_record: :remand_decided)
  end

  let(:appeal_full_grant) do
    Generators::Appeal.build(vacols_record: :full_grant_decided)
  end

  context ".get_decision_type" do
    it "returns the right decision type based on the appeal information passed in" do
      expect(ClaimEstablishment.get_decision_type(appeal_full_grant)).to eq(:full_grant)
      expect(ClaimEstablishment.get_decision_type(appeal_remand)).to eq(:remand)
    end
  end

  context "#appeal=" do
    let(:claim_establishment) { ClaimEstablishment.new }

    it "sets the decision_type" do
      claim_establishment.appeal = appeal_remand
      expect(claim_establishment).to be_remand

      claim_establishment.appeal = appeal_full_grant
      expect(claim_establishment).to be_full_grant
    end
  end

  context "#ep_description" do
    subject { claim_establishment.ep_description }

    let(:claim_establishment) { ClaimEstablishment.new(ep_code: ep_code) }

    context "when ep_code doesn't exist" do
      let(:ep_code) { "BLARGYBLARG" }
      it { is_expected.to be_nil }
    end

    context "when ep_code does exist" do
      let(:ep_code) { "170RBVAG" }
      it { is_expected.to eq("170RBVAG - Remand with BVA Grant") }
    end
  end

  context "#sent_email" do
    subject { claim_establishment.sent_email }

    let(:claim_establishment) do
      ClaimEstablishment.new(email_recipient: email_recipient, email_ro_id: email_ro_id)
    end
    let(:email_ro_id) { nil }
    let(:email_recipient) { nil }

    context "when email_recipient is nil" do
      let(:email_ro_id) { "RO04" }
      it { is_expected.to be_nil }
    end

    context "when email_recipient is set" do
      let(:email_recipient) { "johnson@va.gov" }
      it { is_expected.to have_attributes(recipient: "johnson@va.gov", ro_name: "Unknown") }

      context "when email_ro_id is set" do
        let(:email_ro_id) { "RO04" }
        it { is_expected.to have_attributes(recipient: "johnson@va.gov", ro_name: "Providence, RI") }
      end
    end
  end
end

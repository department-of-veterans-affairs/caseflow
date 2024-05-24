# frozen_string_literal: true

describe Seeds::CaseDistributionAuditLeverEntries do
  describe "#seed!" do
    let(:user) { create(:user) }
    subject { described_class.new.seed! }

    before do
      CDAControlGroup.singleton.add_user(user)
      OrganizationsUser.make_user_admin(user, CDAControlGroup.singleton)
      create(:case_distribution_lever, :alternative_batch_size)
    end

    it "creates audit entry for a lever" do
      expect { subject }.to_not raise_error
      expect(CaseDistributionAuditLeverEntry.count).to eq(1)
      expect(CaseDistributionAuditLeverEntry.first.update_value).to eq("20")
    end
  end
end

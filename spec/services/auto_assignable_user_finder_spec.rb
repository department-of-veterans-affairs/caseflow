# frozen_string_literal: true

describe AutoAssignableUserFinder do
  subject(:described) { described_class.new }

  let(:mock_sensitivity_checker) { instance_double(ExternalApi::BGSService) }

  before do
    allow(ExternalApi::BGSService).to receive(:new).and_return(mock_sensitivity_checker)
  end

  describe "#assignable_users_exist?" do
    before do
      5.times do
        create(:user)
      end
    end

    context "when there are no assignable users" do
      it "returns false" do
        expect(described.assignable_users_exist?).to eq(false)
      end
    end

    context "when there are assignable users" do
      let(:intake_user) { create(:intake_user) }
      let!(:org_user) { create(:organizations_user, organization: InboundOpsTeam.singleton, user: intake_user) }

      it "returns true" do
        expect(described.assignable_users_exist?).to eq(true)
      end
    end
  end

  describe "#get_first_assignable_user" do
    let(:veteran) { create(:veteran) }
    let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }

    xit "returns the first assignable user" do
    end

    context "with NOD correspondence" do
      xit "returns the first assignable NOD user" do
      end
    end
  end
end

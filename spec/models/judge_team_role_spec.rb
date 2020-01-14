# frozen_string_literal: true

describe JudgeTeamRole, :postgres do
  describe ".create" do
    subject { JudgeTeamRole.create!(params) }

    context "when no organizations_user is passed as argument when instantiating" do
      let(:params) {}

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when organizations_user is passed as argument when instantiating" do
      let(:params) { { organizations_user: create(:organizations_user) } }

      it "successfully creates the object" do
        expect { subject }.to_not raise_error
        expect(JudgeTeamRole.count).to eq(1)
      end
    end

    context "when organizations_user_id is passed as argument when instantiating" do
      let(:params) { { organizations_user_id: create(:organizations_user).id } }

      it "successfully creates the object" do
        expect { subject }.to_not raise_error
        expect(JudgeTeamRole.count).to eq(1)
      end
    end
  end

  describe "associations" do
    subject { JudgeTeamRole.create!(organizations_user: create(:organizations_user)) }

    it "is associated with a user" do
      expect(subject.user).to be_a(User)
    end

    it "is associated with an organization" do
      expect(subject.organization).to be_a(Organization)
    end
  end

  describe "JudgeTeamLead" do
    subject { JudgeTeamLead.create!(organizations_user: create(:organizations_user)) }

    it "instantiates properly" do
      expect { subject }.to_not raise_error
      expect(JudgeTeamLead.count).to eq(1)
    end

    it "has expected associations" do
      expect(subject.user).to be_a(User)
      expect(subject.organization).to be_a(Organization)
    end
  end

  describe "DecisionDraftingAttorney" do
    subject { DecisionDraftingAttorney.create!(organizations_user: create(:organizations_user)) }

    it "instantiates properly" do
      expect { subject }.to_not raise_error
      expect(DecisionDraftingAttorney.count).to eq(1)
    end

    it "has expected associations" do
      expect(subject.user).to be_a(User)
      expect(subject.organization).to be_a(Organization)
    end
  end
end

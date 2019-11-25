# frozen_string_literal: true

describe Colocated, :postgres do
  let(:colocated_org) { Colocated.singleton }
  let(:appeal) { nil }

  before do
    create_list(:user, 6).each do |u|
      colocated_org.add_user(u)
    end
  end

  describe ".next_assignee" do
    subject { colocated_org.next_assignee(appeal: appeal) }

    context "when there are no members of the Colocated team" do
      before do
        OrganizationsUser.where(organization: colocated_org).delete_all
      end

      it "should throw an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("Assignee pool can't be blank")
        end
      end
    end

    context "when no appeal is specified" do
      it "should return the first member of the Colocated team" do
        expect(subject).to eq(colocated_org.users.first)
      end
    end

    context "when appeal is specified" do
      let(:appeal) { create(:appeal) }
      it "should return the first member of the Colocated team" do
        expect(subject).to eq(colocated_org.users.first)
      end
    end
  end

  describe ".automatically_assign_to_member?" do
    subject { colocated_org.automatically_assign_to_member? }

    it "should return true" do
      expect(subject).to eq(true)
    end

    context "when there are no members of the Colocated team" do
      before do
        OrganizationsUser.where(organization: colocated_org).delete_all
      end

      it "should throw an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("Assignee pool can't be blank")
        end
      end
    end
  end
end

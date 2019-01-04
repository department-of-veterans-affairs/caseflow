describe Colocated do
  let(:colocated_org) { Colocated.singleton }
  let(:task_class) { nil }

  before do
    FactoryBot.create_list(:user, 6).each do |u|
      OrganizationsUser.add_user_to_organization(u, colocated_org)
    end
  end

  describe ".next_assignee" do
    subject { colocated_org.next_assignee(task_class) }

    context "when there are no members of the Colocated team" do
      before do
        OrganizationsUser.where(organization: colocated_org).delete_all
      end

      it "should throw an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("list_of_assignees cannot be empty")
        end
      end
    end

    context "when no task type is specified" do
      it "should return the first member of the Colocated team" do
        expect(subject).to eq(colocated_org.users.first)
      end
    end

    context "when task type is specified" do
      let(:task_class) { GenericTask }
      it "should return the first member of the Colocated team" do
        expect(subject).to eq(colocated_org.users.first)
      end
    end
  end

  describe ".automatically_assign_to_member?" do
    subject { colocated_org.automatically_assign_to_member?(task_class) }

    context "when there are no members of the Colocated team" do
      before do
        OrganizationsUser.where(organization: colocated_org).delete_all
      end

      it "should throw an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("list_of_assignees cannot be empty")
        end
      end
    end

    context "when no task type is specified" do
      it "should return true" do
        expect(subject).to eq(true)
      end
    end

    context "when task type is specified" do
      let(:task_class) { GenericTask }
      it "should return true" do
        expect(subject).to eq(true)
      end
    end
  end
end

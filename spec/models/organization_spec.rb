describe Organization do
  describe "#user_has_access" do
    let(:org) { create(:organization) }
    let(:user) { create(:user) }

    context "when user not a member of organization" do
      it "should return false" do
        expect(org.user_has_access?(user)).to be_falsey
      end
    end

    context "when user is a member of organization" do
      before { OrganizationsUser.add_user_to_organization(user, org) }
      it "should return true" do
        expect(org.user_has_access?(user)).to be_truthy
      end
    end
  end

  describe ".users" do
    context "when organization has no members" do
      let(:org) { create(:organization) }
      it "should return an empty list" do
        expect(org.users).to eq([])
      end
    end

    context "when organization has members" do
      let(:org) { create(:organization) }
      let(:member_cnt) { 5 }
      let(:users) { create_list(:user, member_cnt) }
      before { users.each { |u| OrganizationsUser.add_user_to_organization(u, org) } }

      it "should return a non-empty list of members" do
        expect(org.users.length).to eq(member_cnt)
      end
    end
  end

  describe ".assignable" do
    let(:user) { create(:user) }
    let!(:organization) { create(:organization, name: "Test") }
    let!(:other_organization) { create(:organization, name: "Org") }

    context "when current task is assigned to a user" do
      let(:task) { create(:generic_task, assigned_to: user) }

      it "returns a list without that organization" do
        expect(Organization.assignable(task)).to match_array([organization, other_organization])
      end
    end

    context "when current task is assigned to an organization" do
      let(:task) { create(:generic_task, assigned_to: organization) }

      it "returns a list without that organization" do
        expect(Organization.assignable(task)).to eq([other_organization])
      end
    end

    context "when current task is assigned to a user and its parent is assigned to a user to an organization" do
      let(:parent) { create(:generic_task, assigned_to: organization) }
      let(:task) { create(:generic_task, assigned_to: user, parent: parent) }

      it "returns a list without that organization" do
        expect(Organization.assignable(task)).to eq([other_organization])
      end
    end

    context "when there is a named Organization as a subclass of Organization" do
      let(:task) { create(:generic_task, assigned_to: user) }
      before { QualityReview.singleton }

      it "should be included in the list of organizations returned by assignable" do
        expect(Organization.assignable(task).length).to eq(3)
      end
    end

    context "when organization cannot receive tasks" do
      let(:task) { create(:generic_task, assigned_to: user) }
      before { Bva.singleton }

      it "should not be included in the list of organizations returned by assignable" do
        expect(Organization.assignable(task)).to match_array([organization, other_organization])
      end
    end
  end

  describe ".user_is_admin?" do
    let(:org) { create(:organization) }
    let(:user) { create(:user) }

    context "when user is not an admin for the organization" do
      before { OrganizationsUser.add_user_to_organization(user, org) }
      it "should return false" do
        expect(org.user_is_admin?(user)).to eq(false)
      end
    end

    context "when user is an admin for the organization" do
      before { OrganizationsUser.make_user_admin(user, org) }
      it "should return true" do
        expect(org.user_is_admin?(user)).to eq(true)
      end
    end
  end
end

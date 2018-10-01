describe Organization do
  describe "#user_has_access" do
    let(:field) { "sdept" }
    let(:fld_val) { "USA" }

    let(:org) { create(:organization) }
    let!(:sfo) { StaffFieldForOrganization.create!(organization: org, name: field, values: [fld_val]) }
    let(:user) { create(:user) }

    context "when user not a member of organization" do
      it "should return false" do
        expect(org.user_has_access?(user)).to be_falsey
      end
    end

    context "when user is a member of organization" do
      before { FactoryBot.create(:staff, user: user, "#{field}": fld_val) }
      it "should return true" do
        expect(org.user_has_access?(user)).to be_truthy
      end
    end
  end

  describe ".members" do
    context "when organization has no members" do
      let(:org) { create(:organization) }
      it "should return an empty list" do
        expect(org.members).to eq([])
      end
    end

    context "when organization has members" do
      let(:field) { "sdept" }
      let(:fld_val) { "ORG" }

      let(:org) { create(:organization) }
      let!(:sfo) { StaffFieldForOrganization.create!(organization: org, name: field, values: [fld_val]) }
      let(:member_cnt) { 5 }
      let(:users) { create_list(:user, member_cnt) }

      before { users.each { |u| FactoryBot.create(:staff, user: u, "#{field}": fld_val) } }

      it "should return a non-empty list of members" do
        expect(org.members.length).to eq(member_cnt)
      end
    end

    context "when multiple organizations filter on same field" do
      let(:dispatch_org) { FactoryBot.create(:organization, name: "Board Dispatch") }
      let(:dispatch_cnt) { 36 }
      let(:dispatch_users) { FactoryBot.create_list(:user, dispatch_cnt) }

      let(:colocated_org) { FactoryBot.create(:organization, name: "Co-located Admin") }
      let(:colocated_cnt) { 17 }
      let(:colocated_users) { FactoryBot.create_list(:user, colocated_cnt) }

      before do
        StaffFieldForOrganization.create!(organization: dispatch_org, name: "sdept", values: %w[DSP])
        StaffFieldForOrganization.create!(organization: dispatch_org, name: "stitle", values: %w[A1 A2], exclude: true)
        dispatch_users.each { |u| FactoryBot.create(:staff, :dispatch_role, user: u) }

        StaffFieldForOrganization.create!(organization: colocated_org, name: "stitle", values: %w[A1 A2])
        colocated_users.each { |u| FactoryBot.create(:staff, :colocated_role, user: u, sdept: "DSP") }
      end

      it "dispatch should only return members of dispatch" do
        expect(dispatch_org.members.length).to eq(dispatch_cnt)
      end

      it "colocated should only return members of colocated" do
        expect(colocated_org.members.length).to eq(colocated_cnt)
      end
    end
  end
end

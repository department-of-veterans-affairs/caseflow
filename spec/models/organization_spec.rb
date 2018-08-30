describe Organization do
  context "#user_has_access" do
    let(:org) { create(:organization) }
    let(:user) do
      create(:user)
    end

    context "when user not a member of organization" do
      it "should return false" do
        expect(org.user_has_access?(user)).to be_falsey
      end
    end

    context "when user is a member of organization" do
      before { FeatureToggle.enable!(org.feature.to_sym, users: [user.css_id]) }
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
      let(:org) { create(:organization) }
      let(:member_cnt) { 5 }
      let(:users) { create_list(:user, member_cnt) }
      before { users.each { |u| FeatureToggle.enable!(org.feature.to_sym, users: [u.css_id]) } }

      it "should return an empty list" do
        expect(org.members.length).to eq(member_cnt)
      end
    end
  end
end

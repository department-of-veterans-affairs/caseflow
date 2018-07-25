describe Organization do
  context "#user_has_access" do
    let(:user) do
      create(:user)
    end

    it "should return false" do
      expect(Organization.new.user_has_access?(user)).to be_falsey
    end
  end
end

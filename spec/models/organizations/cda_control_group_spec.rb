# frozen_string_literal: true

describe CDAControlGroup do
  describe ".singleton" do
    it "is named correctly" do
      expect(CDAControlGroup.singleton).to have_attributes(name: "Case Distro Algorithm Control")
    end

    it "will only have one CDAControlGroup no matter how many times it is run" do
      CDAControlGroup.singleton
      CDAControlGroup.singleton
      expect(Organization.where(name: "Case Distro Algorithm Control").count).to eq(1)
    end

    it "will have the correct url name" do
      expect(CDAControlGroup.singleton).to have_attributes(url: "cda-control-group")
    end
  end

  describe ".users_can_view_levers?" do
    it "should always be true" do
      expect(CDAControlGroup.singleton.users_can_view_levers?).to eq(true)
    end
  end

  describe "can_receive_task?" do
    it "should always be false" do
      expect(CDAControlGroup.singleton.can_receive_task?("some_task")).to eq(false)
    end
  end
end

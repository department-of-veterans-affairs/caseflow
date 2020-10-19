# frozen_string_literal: true

describe CavcLitigationSupport do
  describe ".singleton" do
    it "is named correctly" do
      expect(CavcLitigationSupport.singleton).to have_attributes(name: "CAVC Litigation Support")
    end
  end

  describe ".users_can_create_mail_task?" do
    it "should always be true" do
      expect(CavcLitigationSupport.singleton.users_can_create_mail_task?).to eq(true)
    end
  end
end

# frozen_string_literal: true

describe ClerkOfTheBoard do
  describe ".singleton" do
    it "is named correctly" do
      expect(ClerkOfTheBoard.singleton).to have_attributes(name: "Clerk of the Board")
    end
  end

  describe ".users_can_create_mail_task?" do
    it "should always be true" do
      expect(ClerkOfTheBoard.singleton.users_can_create_mail_task?).to eq(true)
    end
  end
end

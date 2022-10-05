# frozen_string_literal: true

describe SupervisorySeniorCouncil do
  describe ".singleton" do
    it "is named correctly" do
      expect(SupervisorySeniorCouncil.singleton).to have_attributes(name: "Supervisory Senior Council")
    end

    it "will only have one SupervisorySeniorCouncil no matter how many times it is run" do
      SupervisorySeniorCouncil.singleton
      SupervisorySeniorCouncil.singleton
      expect(Organization.where(name: "Supervisory Senior Council").count).to eq(1)
    end

    it "will have the correct url name" do
      expect(SupervisorySeniorCouncil.singleton).to have_attributes(url: "supervisory-senior-council")
    end
  end

  describe ".users_can_create_mail_task?" do
    it "should always be true" do
      expect(SupervisorySeniorCouncil.singleton.users_can_create_mail_task?).to eq(true)
    end
  end

  describe ".can_receive_task?" do
    it "returns false because the COB hasn't started using Queue yet" do
      expect(SupervisorySeniorCouncil.singleton.can_receive_task?(nil)).to eq(false)
    end
  end
end

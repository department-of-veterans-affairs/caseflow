# frozen_string_literal: true

describe OccTeam do
  describe ".singleton" do
    it "is named correctly" do
      expect(OccTeam.singleton).to have_attributes(name: "Office of Chief Counsel")
    end
  end
end

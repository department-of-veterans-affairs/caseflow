# frozen_string_literal: true

describe OaiTeam do
  describe ".singleton" do
    it "is named correctly" do
      expect(OaiTeam.singleton).to have_attributes(name: "Office of Assessment and Improvement")
    end
  end
end

# frozen_string_literal: true

describe CavcLitigationSupport do
  describe ".singleton" do
    it "is named correctly" do
      expect(CavcLitigationSupport.singleton).to have_attributes(name: "CAVC Litigation Support")
    end
  end
end

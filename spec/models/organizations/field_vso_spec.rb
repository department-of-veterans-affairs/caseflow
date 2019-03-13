# frozen_string_literal: true

describe FieldVso do
  describe ".create!" do
    it "creates an associated VsoConfig object with no ihp_dockets when it is created" do
      vso = FieldVso.create!(name: "VSO name here")
      expect(vso.vso_config.ihp_dockets).to eq([])
    end
  end
end

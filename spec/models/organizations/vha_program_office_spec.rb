# frozen_string_literal: true

describe VhaProgramOffice, :postgres do
  let(:program_office) { VhaProgramOffice.create!(name: "Program Office", url: "Program Office") }

  describe ".create!" do
    it "creates a Vha Program Office" do
      expect(program_office.name).to eq("Program Office")
    end
  end
end

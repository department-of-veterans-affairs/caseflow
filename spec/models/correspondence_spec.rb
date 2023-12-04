# frozen_string_literal: true

RSpec.describe Correspondence, type: :model do
  describe "Relationships" do
    it { Correspondence.reflect_on_association(:prior_correspondence).macro.should eq(:belongs_to) }
  end

  describe "associations" do
    it "belongs to prior correspondence" do
      association = Correspondence.reflect_on_association(:prior_correspondence)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be_truthy
    end

    it "can add and save associated records" do
      correspondence = FactoryBot.create(:correspondence)
      associated_correspondence = FactoryBot.create(:correspondence)

      # Add the associated correspondence
      correspondence.prior_correspondence = associated_correspondence

      # Save the correspondence
      correspondence.save

      # Retrieve the correspondence from the database
      saved_correspondence = Correspondence.find(correspondence.id)

      # Assert that the associated correspondence is saved
      expect(saved_correspondence.prior_correspondence).to eq(associated_correspondence)
    end
  end
end

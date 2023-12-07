# frozen_string_literal: true

RSpec.describe Correspondence, type: :model do

  let!(:current_user) do
    create(:user, roles: ["Mail Intake"])
  end

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

  describe "Create Correspondence Root Task and Review Package task as child" do
    it "Create Root Task and Review Package task for correspondence" do

      correspondence = Correspondence.create!(
        uuid: SecureRandom.uuid,
        portal_entry_date: Time.zone.now,
        source_type: "Mail",
        package_document_type_id: 15,
        correspondence_type_id: 8,
        cmp_queue_id: 1,
        cmp_packet_number: 9999999999,
        va_date_of_receipt: Time.zone.yesterday,
        notes: "This is a note from CMP.",
        assigned_by_id: 81,
        veteran_id: 1,
        prior_correspondence_id: 999999
      )

      crt = CorrespondenceRootTask.find_by(appeal_id: correspondence.id)
      expect(crt.appeal_id).to eq(correspondence.id)
      expect(crt.status).to eq("on_hold")
      expect(crt.type).to eq("CorrespondenceRootTask")

      rpt = CorrespondenceRootTask.find_by(appeal_id: correspondence.id, type: "ReviewPackageTask")
      expect(rpt.appeal_id).to eq(correspondence.id)
      expect(rpt.status).to eq("assigned")
      expect(rpt.type).to eq("ReviewPackageTask")
      expect(rpt.parent_id).to eq(crt.id)

    end
  end
end

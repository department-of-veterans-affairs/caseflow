# frozen_string_literal: true

RSpec.describe Correspondence, type: :model do
  let!(:current_user) do
    create(:user, roles: ["Mail Intake"])
  end

  it "exists" do
    c = Correspondence.new
    expect(c).to be_a(Correspondence)
  end

  it "can be bi-directionally related to other correspondences" do
    c_1 = Correspondence.create!(
      updated_by_id: -1,
      correspondence_type_id: -1,
      assigned_by_id: -1,
      veteran_id: -1,
      package_document_type_id: -1
    )
    c_2 = Correspondence.create!(
      updated_by_id: -2,
      correspondence_type_id: -2,
      assigned_by_id: -2,
      veteran_id: -2,
      package_document_type_id: -2
    )

    expect(c_1.related_correspondences).to eq([])
    expect(c_2.related_correspondences).to eq([])

    cr = CorrespondenceRelation.create!(correspondence_id: c_1.id, related_correspondence_id: c_2.id)

    expect(c_1.reload.related_correspondences).to eq([c_2])
    expect(c_2.reload.related_correspondences).to eq([c_1])

    cr.destroy

    expect(c_1.reload.related_correspondences).to eq([])
    expect(c_2.reload.related_correspondences).to eq([])
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
        cmp_packet_number: 9_999_999_999,
        va_date_of_receipt: Time.zone.yesterday,
        notes: "This is a note from CMP.",
        assigned_by_id: 81,
        updated_by_id: 81,
        veteran_id: 1
      )

      ct = CorrespondenceTask.find_by(appeal_id: correspondence.id, type: "CorrespondenceTask")
      expect(ct.appeal_id).to eq(correspondence.id)
      expect(ct.status).to eq("on_hold")
      expect(ct.type).to eq("CorrespondenceTask")
      expect(ct.assigned_to).to eq(MailTeamSupervisor.singleton)

      crt = CorrespondenceRootTask.find_by(appeal_id: correspondence.id)
      expect(crt.appeal_id).to eq(correspondence.id)
      expect(crt.status).to eq("on_hold")
      expect(crt.type).to eq("CorrespondenceRootTask")
      expect(crt.parent_id).to eq(ct.id)
      expect(crt.assigned_to).to eq(MailTeamSupervisor.singleton)

      rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
      expect(rpt.appeal_id).to eq(correspondence.id)
      expect(rpt.status).to eq("unassigned")
      expect(rpt.type).to eq("ReviewPackageTask")
      expect(rpt.parent_id).to eq(crt.id)
      expect(rpt.assigned_to).to eq(MailTeamSupervisor.singleton)
    end
  end
end

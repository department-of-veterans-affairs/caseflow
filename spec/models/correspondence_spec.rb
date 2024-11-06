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
    c_1 = create(:correspondence)
    c_2 = create(:correspondence)

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
      correspondence = create(:correspondence)

      crt = CorrespondenceRootTask.find_by(appeal_id: correspondence.id)
      expect(crt.appeal_id).to eq(correspondence.id)
      expect(crt.status).to eq("on_hold")
      expect(crt.type).to eq("CorrespondenceRootTask")
      expect(crt.assigned_to).to eq(InboundOpsTeam.singleton)

      rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
      expect(rpt.appeal_id).to eq(correspondence.id)
      expect(rpt.status).to eq("unassigned")
      expect(rpt.type).to eq("ReviewPackageTask")
      expect(rpt.parent_id).to eq(crt.id)
      expect(rpt.assigned_to).to eq(InboundOpsTeam.singleton)
    end
  end

  describe "Test CorrespondenceRootTask methods" do
    it "correctly returns the date using the completed_by_date method" do
      create(:correspondence)

      correspondence_root_task = CorrespondenceRootTask.first
      closed_date = 1.day.ago
      correspondence_root_task.update!(closed_at: closed_date)
      expect correspondence_root_task.completed_by_date == closed_date

      correspondence_root_task.update!(closed_at: nil)
      review_package_task = ReviewPackageTask.first
      review_package_task.update!(closed_at: closed_date)
      expect correspondence_root_task.completed_by_date == closed_date
    end
  end

  describe "Test self.prior_mail" do
    it "returns other mail that is not identical to current one" do
      veteran = create(:veteran)
      3.times { create(:correspondence, veteran: veteran) }
      correspondence_first = Correspondence.first
      prior_mail = Correspondence.prior_mail(correspondence_first, correspondence_first.uuid)
      expect(prior_mail).not_to include(correspondence_first)
    end
  end
end

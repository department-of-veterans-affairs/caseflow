# frozen_string_literal: true

RSpec.describe Correspondence, type: :model do
  it "exists" do
    c = Correspondence.create!
    expect(c).to be_a(Correspondence)
  end

  it "can be bi-directionally related to other correspondences" do
    c_1 = Correspondence.create!
    c_2 = Correspondence.create!

    expect(c_1.related_correspondences).to eq([])
    expect(c_2.related_correspondences).to eq([])

    cr = CorrespondenceRelation.create!(correspondence_id: c_1.id, related_correspondence_id: c_2.id)

    expect(c_1.reload.related_correspondences).to eq([c_2])
    expect(c_2.reload.related_correspondences).to eq([c_1])

    cr.destroy

    expect(c_1.reload.related_correspondences).to eq([])
    expect(c_2.reload.related_correspondences).to eq([])
  end
end

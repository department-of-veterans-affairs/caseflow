# frozen_string_literal: true

RSpec.describe CorrespondencesAppeal, type: :model do
  let(:correspondence) { create(:correspondence) }
  let(:appeal) { create(:appeal, veteran: create(:veteran)) }

  before do
    @subject = CorrespondencesAppeal.create!(
      correspondence_id: correspondence.id,
      appeal_id: appeal.id)
  end

  it "exists" do
    expect(@subject).to be_a(CorrespondencesAppeal)
  end

  it "belongs to a correspondence" do
    expect(@subject.correspondence).to eq(correspondence)
  end

  it "belongs to an appeal" do
    expect(@subject.appeal).to eq(appeal)
  end

  it "enables a many-to-many relationship between correspondences and appeals" do
    expect(appeal.correspondences).to eq([correspondence])
    expect(correspondence.appeals).to eq([appeal])
  end
end

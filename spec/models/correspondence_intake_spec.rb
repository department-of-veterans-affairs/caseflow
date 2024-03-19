# frozen_string_literal: true

RSpec.describe CorrespondenceIntake, type: :model do
  describe "relationships" do
    it { CorrespondenceIntake.reflect_on_association(:correspondence).macro.should eq(:belongs_to) }
    it { CorrespondenceIntake.reflect_on_association(:user).macro.should eq(:belongs_to) }
  end

  describe "Record entry" do
    before do
      CorrespondenceType.create!(
        name: "a correspondence type"
      )
      PackageDocumentType.create!

      FactoryBot.create(:veteran)
    end
    it "can be created" do
      user = User.create!(css_id: "User", station_id: "1")
      correspondence = Correspondence.create!(
        updated_by_id: User.first.id,
        correspondence_type: CorrespondenceType.first,
        assigned_by_id: User.first.id,
        veteran_id: Veteran.first.id,
        package_document_type: PackageDocumentType.first
      )
      subject = CorrespondenceIntake.create!(
        correspondence_id: correspondence.id,
        user_id: user.id,
        current_step: 1,
        redux_store: 1
      )

      expect(subject).to be_a(CorrespondenceIntake)
    end

    it "validates :correspondence_id and :user_id" do
      user = User.create!(css_id: "User", station_id: "1")
      correspondence = Correspondence.create!(
        updated_by_id: User.first.id,
        correspondence_type: CorrespondenceType.first,
        assigned_by_id: User.first.id,
        veteran_id: Veteran.first.id,
        package_document_type: PackageDocumentType.first
      )

      expect { CorrespondenceIntake.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { CorrespondenceIntake.create!(correspondence_id: correspondence.id) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect { CorrespondenceIntake.create!(user_id: user.id) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

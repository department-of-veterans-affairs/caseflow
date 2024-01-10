# frozen_string_literal: true

RSpec.describe CorrespondenceIntake, type: :model do
  describe "relationships" do
    it { CorrespondenceIntake.reflect_on_association(:correspondence).macro.should eq(:belongs_to) }
    it { CorrespondenceIntake.reflect_on_association(:user).macro.should eq(:belongs_to) }
  end

  describe "Record entry" do
    it "can be created" do
      correspondence = Correspondence.create!(
        updated_by_id: 1,
        correspondence_type_id: 1,
        assigned_by_id: 1,
        veteran_id: 1,
        package_document_type_id: 1
      )
      user = User.create!(css_id: "User", station_id: "1")
      subject = CorrespondenceIntake.create!(
        correspondence_id: correspondence.id,
        user_id: user.id,
        current_step: 1,
        redux_store: 1
      )

      expect(subject).to be_a(CorrespondenceIntake)
    end

    it "validates :correspondence_id and :user_id" do
      correspondence = Correspondence.create!(
        correspondence_type_id: 1,
        assigned_by_id: 1,
        updated_by_id: 1,
        veteran_id: 1,
        package_document_type_id: 1
      )
      user = User.create!(css_id: "User", station_id: "1")

      expect { CorrespondenceIntake.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { CorrespondenceIntake.create!(correspondence_id: correspondence.id) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect { CorrespondenceIntake.create!(user_id: user.id) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

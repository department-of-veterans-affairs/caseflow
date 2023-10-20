RSpec.describe CorrespondenceIntake, type: :model do
  describe 'Relationships' do
    it { CorrespondenceIntake.reflect_on_association(:correspondence).macro.should  eq(:belongs_to) }
  end
end

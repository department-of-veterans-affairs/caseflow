# frozen_string_literal: true

describe BatchAutoAssignmentAttempt do
  describe "Associations" do
    it { should belong_to(:user).required }
    it { should have_many(:individual_auto_assignment_attempts).dependent(:destroy) }
  end

  describe "Validations" do
    BatchAutoAssignmentAttempt::VALID_STATUSES.each do |status_name|
      it { should allow_value(status_name).for(:status) }
    end
  end
end

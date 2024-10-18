# frozen_string_literal: true

describe IndividualAutoAssignmentAttempt do
  describe "Associations" do
    it { should belong_to(:user).required }
    it { should belong_to(:correspondence).required }
    it { should belong_to(:batch_auto_assignment_attempt).required }
  end

  describe "Validations" do
    it { should allow_value(%w[true false]).for(:nod) }
    it { should_not allow_value(nil).for(:nod) }

    IndividualAutoAssignmentAttempt::VALID_STATUSES.each do |status_name|
      it { should allow_value(status_name).for(:status) }
    end
  end
end

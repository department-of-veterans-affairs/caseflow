# frozen_string_literal: true

describe AutoAssignableUserFinder do
  let!(:current_user) { create(:user) }
  subject(:described) { described_class.new(current_user) }

  let(:veteran) { create(:veteran) }

  let!(:bgs) { BGSService.new }
  let(:mock_sensitivity_checker) { instance_double(BGSService, can_access?: true) }

  before do
    allow(BGSService).to receive(:new).and_return(mock_sensitivity_checker)

    allow(mock_sensitivity_checker).to receive(:sensitivity_level_for_user) do |user|
      bgs.sensitivity_level_for_user(user)
    end

    allow(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran) do |vet|
      bgs.sensitivity_level_for_veteran(vet)
    end

    allow(mock_sensitivity_checker).to receive(:fetch_person_info) do |vbms_id|
      bgs.fetch_person_info(vbms_id)
    end

    allow(mock_sensitivity_checker).to receive(:fetch_veteran_info) do |vbms_id|
      bgs.fetch_veteran_info(vbms_id)
    end
    FeatureToggle.enable!(:correspondence_queue)
  end

  def generate_assigned_review_package_tasks(amount:, user:)
    amount.times do
      created = create(:correspondence, veteran_id: veteran.id)
      created.review_package_task.update!(
        assigned_to: user,
        status: Constants.TASK_STATUSES.assigned
      )
    end
  end

  describe "#assignable_users_exist?" do
    context "when there are no assignable users" do
      before do
        5.times do
          create(:user)
        end
      end

      it "returns false" do
        expect(described.assignable_users_exist?).to eq(false)
      end

      context "when all users are already at capacity" do
        let!(:user_1) { create(:correspondence_auto_assignable_user) }

        it "returns nil" do
          generate_assigned_review_package_tasks(amount: CorrespondenceAutoAssignmentLever.max_capacity, user: user_1)
          expect(described.assignable_users_exist?).to eq(false)
        end
      end
    end

    context "when there are assignable users" do
      before do
        5.times do
          create(:correspondence_auto_assignable_user)
        end
      end

      it "returns true" do
        expect(described.assignable_users_exist?).to eq(true)
      end
    end
  end

  describe "#get_first_assignable_user" do
    context "when assignable users are NOT present" do
      let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }

      it "returns nil" do
        expect(described.get_first_assignable_user(correspondence: correspondence)).to be nil
      end

      context "when all users are already at capacity" do
        let!(:user_1) { create(:correspondence_auto_assignable_user) }
        let!(:user_2) { create(:correspondence_auto_assignable_user) }

        it "returns nil" do
          generate_assigned_review_package_tasks(amount: CorrespondenceAutoAssignmentLever.max_capacity, user: user_1)
          generate_assigned_review_package_tasks(amount: CorrespondenceAutoAssignmentLever.max_capacity, user: user_2)

          expect(described.get_first_assignable_user(correspondence: correspondence)).to be nil
        end
      end

      context "with NOD correspondence" do
        let!(:correspondence_nod) do
          create(:correspondence, :nod, veteran_id: veteran.id)
        end
        let!(:user_1) { create(:correspondence_auto_assignable_user) }
        let!(:user_2) { create(:correspondence_auto_assignable_user) }

        it "returns nil" do
          expect(described.get_first_assignable_user(correspondence: correspondence_nod)).to be nil
        end
      end
    end

    context "when assignable users are present" do
      let!(:already_assigned) { create(:correspondence_auto_assignable_user) }
      let!(:available) { create(:correspondence_auto_assignable_user) }

      let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }

      context "when one user is assigned more tasks than another" do
        let!(:other_user) { create(:correspondence_auto_assignable_user) }

        before do
          generate_assigned_review_package_tasks(amount: 5, user: available)
          generate_assigned_review_package_tasks(
            amount: CorrespondenceAutoAssignmentLever.max_capacity,
            user: other_user
          )
          generate_assigned_review_package_tasks(amount: 10, user: already_assigned)
        end

        it "returns the user with the fewer number of assigned tasks" do
          expect(described.get_first_assignable_user(correspondence: correspondence)).to eq(available)
        end
      end

      context "with an equal number of assigned tasks" do
        it "returns the user longest waiting for an assignment" do
          generate_assigned_review_package_tasks(amount: 2, user: available)
          generate_assigned_review_package_tasks(amount: 2, user: already_assigned)

          expect(described.get_first_assignable_user(correspondence: correspondence)).to eq(available)
        end
      end

      context "with NOD correspondence" do
        let!(:nod_user) { create(:correspondence_auto_assignable_user, :nod_enabled) }
        let!(:correspondence_nod) do
          create(:correspondence, :nod, veteran_id: veteran.id)
        end

        before do
          generate_assigned_review_package_tasks(amount: 10, user: nod_user)
        end

        it "returns the first assignable NOD user" do
          expect(described.get_first_assignable_user(correspondence: correspondence_nod)).to eq(nod_user)
        end
      end
    end

    context "with inbound ops team super user" do
      let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }
      let!(:normal_user) { create(:correspondence_auto_assignable_user) }
      let!(:super_user) { create(:correspondence_auto_assignable_user, :super_user) }

      context "when super user has available capacity" do
        before do
          create(:merge_package_task)
          create(:reassign_package_task)
          create(:split_package_task)
          generate_assigned_review_package_tasks(amount: 1, user: super_user)
          generate_assigned_review_package_tasks(amount: 5, user: normal_user)
        end

        it "returns the super user" do
          expect(described.get_first_assignable_user(correspondence: correspondence)).to eq(super_user)
        end
      end

      context "when super user has NO available capacity" do
        before do
          create(:merge_package_task, assigned_to: super_user)
          create(:reassign_package_task, assigned_to: super_user)
          create(:split_package_task, assigned_to: super_user)
          generate_assigned_review_package_tasks(
            amount: CorrespondenceAutoAssignmentLever.max_capacity - 3,
            user: super_user
          )
          generate_assigned_review_package_tasks(
            amount: CorrespondenceAutoAssignmentLever.max_capacity - 1,
            user: normal_user
          )
        end

        it "returns another eligible user" do
          expect(described.get_first_assignable_user(correspondence: correspondence)).to eq(normal_user)
        end
      end
    end

    context "with sensitivity level check" do
      let(:high_sensitivity_level) { 9 }
      let(:low_sensitivity_level) { 1 }

      let!(:correspondence) { create(:correspondence, veteran_id: veteran.id) }
      let!(:user_1) { create(:correspondence_auto_assignable_user) }
      let!(:user_2) { create(:correspondence_auto_assignable_user) }

      context "with no BGSService errors" do
        before do
          expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
            .with(user_1).and_return(low_sensitivity_level)
          expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
            .with(user_2).and_return(low_sensitivity_level)
          expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran)
            .with(correspondence.veteran).twice.and_return(high_sensitivity_level)
          expect(BGSService).to receive(:new).and_return(mock_sensitivity_checker)
        end

        it "does not allow access for users without the correct sensitivity level" do
          expect(described.get_first_assignable_user(correspondence: correspondence)).to be nil
        end
      end

      context "when the BGSService raises an error" do
        before do
          expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
            .with(user_1).and_raise("Test BGS error")
          expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
            .with(user_2).and_return(high_sensitivity_level)
          expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran)
            .with(correspondence.veteran).and_return(high_sensitivity_level)
          expect(BGSService).to receive(:new).and_return(mock_sensitivity_checker)
        end

        it "continues iterating through all assignable users" do
          expect(described.get_first_assignable_user(correspondence: correspondence)).to eq(user_2)
        end
      end
    end
  end
end

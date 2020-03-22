# frozen_string_literal: true

shared_context "AMA Tableau SQL", shared_context: :metadata do
  before do
    CachedUser.sync_from_vacols
  end

  let(:judge) do
    staff = create(:staff)
    user = create(:user, full_name: "A Judge", css_id: staff.sdomainid)
    allow(user).to receive(:judge_in_vacols?) { true }
    user
  end
  let(:attorney) do
    staff = create(:staff)
    user = create(:user, full_name: "Anne Attorney", css_id: staff.sdomainid)
    allow(user).to receive(:attorney_in_vacols?) { true }
    user
  end
  let!(:aod_person) { create(:person, date_of_birth: 76.years.ago, participant_id: aod_veteran.participant_id) }
  let!(:person) { create(:person, date_of_birth: 65.years.ago, participant_id: veteran.participant_id) }
  let(:aod_veteran) { create(:veteran) }
  let(:veteran) { create(:veteran) }
  let!(:not_distributed) do
    create(:appeal, :ready_for_distribution, veteran_file_number: veteran.file_number)
  end
  let!(:not_distributed_with_timed_hold) do
    create(:appeal, :ready_for_distribution, veteran_file_number: aod_veteran.file_number).tap do |appeal|
      create(:timed_hold_task, parent: appeal.root_task)
    end
  end
  let!(:distributed_to_judge) { create(:appeal, :assigned_to_judge) }
  let!(:assigned_to_attorney) { create(:ama_attorney_task, parent: create(:root_task)) }
  let!(:assigned_to_colocated) { create(:ama_colocated_task, assigned_to: attorney, parent: create(:root_task)) }
  let!(:decision_in_progress) do
    create(:ama_attorney_task, :in_progress, assigned_by: judge, parent: create(:root_task))
  end
  let!(:decision_ready_for_signature) do
    create(:ama_judge_decision_review_task, :in_progress, parent: create(:root_task))
  end
  let!(:decision_signed) { create(:bva_dispatch_task, :in_progress, parent: create(:root_task)) }
  let!(:decision_dispatched) do
    root_task = create(:root_task)
    create(:bva_dispatch_task, :completed, parent: root_task)
    root_task.completed!
  end
  let!(:dispatched_with_subsequent_assigned_task) do
    root_task = create(:root_task)
    create(:bva_dispatch_task, :completed, parent: root_task)
    create(:ama_attorney_task, assigned_to: attorney, parent: root_task)
  end
  let!(:cancelled) { create(:root_task, :cancelled) }
  let!(:on_hold) { create(:timed_hold_task, parent: create(:root_task)) }
  let!(:misc) { create(:ama_judge_dispatch_return_task, parent: create(:root_task)) }

  let(:expected_report) do
    {
      not_distributed.id => ["1. Not distributed", "00"],
      not_distributed_with_timed_hold.id => ["ON HOLD", "08"],
      distributed_to_judge.id => ["2. Distributed to judge", "01"],
      assigned_to_attorney.id => ["3. Assigned to attorney", "02"],
      dispatched_with_subsequent_assigned_task.id => ["3. Assigned to attorney", "02"],
      assigned_to_colocated.id => ["4. Assigned to colocated", "03"],
      decision_in_progress.id => ["5. Decision in progress", "04"],
      decision_ready_for_signature.id => ["6. Decision ready for signature", "05"],
      decision_signed.id => ["7. Decision signed", "06"],
      decision_dispatched.id => ["8. Decision dispatched", "07"],
      cancelled.id => %w[CANCELLED 09],
      on_hold.id => ["ON HOLD", "08"],
      misc.id => %w[MISC 10]
    }
  end
end

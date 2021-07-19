# frozen_string_literal: true

shared_examples_for "task requiring specific parent" do
  context "parent is the expected type" do
    it "creates task" do
      new_task = subject
      expect(new_task.valid?)
      expect(new_task.errors.messages[:parent]).to be_empty

      expect(appeal.tasks).to include new_task
      expect(parent_task.children).to include new_task
    end
  end

  context "parent task is not the expected type" do
    let(:parent_task) { create(:root_task) }
    it "fails to create task" do
      new_task = subject
      expect(new_task.invalid?).to eq true
      expect(new_task.errors.messages[:parent]).to include(/should be .*/)
    end
  end

  context "parent is nil" do
    let(:parent_task) { nil }
    it "fails to create task" do
      new_task = subject
      expect(new_task.invalid?).to eq true
      expect(new_task.errors.messages[:parent]).to include("can't be blank")
    end
  end
end

shared_examples_for "sort by Appeal Type column" do
  let(:assignee) { create(:organization) }

  before do
    Colocated.singleton.add_user(create(:user))

    vacols_case_types = [:type_original, :type_post_remand, :type_cavc_remand]
    vacols_case_types.each_with_index do |case_type, index|
      appeal = create(:legacy_appeal, vacols_case: create(:case, case_type))
      create(:colocated_task, appeal: appeal, assigned_to: assignee)
      create(:cached_appeal,
             appeal_id: appeal.id,
             docket_number: index,
             appeal_type: LegacyAppeal.name,
             case_type: appeal.type)
    end

    appeals = [
      create(:appeal, :advanced_on_docket_due_to_motion, :type_cavc_remand),
      create(:appeal, :advanced_on_docket_due_to_motion),
      create(:appeal, :type_cavc_remand),
      create(:appeal)
    ]
    appeals.each_with_index do |appeal, index|
      create(:ama_colocated_task, appeal: appeal, assigned_to: assignee)
      create(:cached_appeal,
             appeal_id: appeal.id,
             docket_number: index + vacols_case_types.count,
             appeal_type: Appeal.name,
             case_type: appeal.type,
             is_aod: appeal.aod)
    end
  end

  it "sorts by AOD status, case type, and docket number" do
    # postgres ascending sort sorts booleans [true, false] as [false, true]. We want is_aod appeals to show up
    # first so we sort descending on is_aod
    expected_order = CachedAppeal.order(
      "is_aod desc, CASE WHEN case_type = 'Court Remand' THEN 0 ELSE 1 END, docket_number asc"
    )
    expect(expected_order.first.is_aod).to eq true
    expect(expected_order.first.case_type).to eq Constants.AMA_STREAM_TYPES.court_remand.titlecase
    expect(subject.map { |task| [task.appeal_id, task.appeal_type] }).to eq(
      expected_order.pluck(:appeal_id, :appeal_type)
    )
  end
end

# frozen_string_literal: true

describe TaskTreeRender do

  context ".tree is called on an appeal" do
    let!(:appeal) {
      appeal = create(:appeal, :with_post_intake_tasks)
      root = appeal.root_task
      create(:ama_attorney_task, appeal: appeal)
      create(:ama_judge_task, appeal: appeal, parent: root, created_at: 1.day.ago)
#      create(:ama_judge_decision_review_task, appeal: appeal) # no parent
      create(:ama_attorney_task, appeal: appeal)

      #
      #create(:ama_judge_decision_review_task) # different appeal
      #at = create(:schedule_hearing_task) # no appeal
      #  create(:ama_attorney_task, appeal: appeal)
      appeal
    }

    #subject { appeal.tree_hash(:id) }

    it "returns all tasks for the appeal" do
      # regardless of task status, assignee, etc.
      rows_hash, metadata = appeal.tree_hash
      expect(rows_hash.count).to eq 1
      expect(metadata.rows.count).to eq 6
    end

    # appeal.tree(:id, :status)
    it "returns only specified attributes" do
      rows_hash, metadata = appeal.tree_hash(:id, :status)
      expect(rows_hash.count).to eq 1
      expect(metadata.rows.count).to eq 6
      expect(metadata.col_keys).to eq ["id", "status"]
    end

    # atts = [:id, [:assigned_to, :type]]
    it "returns dereferenced column chain '[:assigned_to, :type]'" do
      rows_hash, metadata = appeal.tree_hash(:id, [:assigned_to, :type])
      expect(rows_hash.count).to eq 1
      expect(metadata.rows.count).to eq 6
      expect(metadata.col_keys).to eq ["id", "[:assigned_to, :type]"]
      expect(metadata.rows[appeal.root_task]["[:assigned_to, :type]"]).to eq appeal.root_task.assigned_to.type
    end

    # atts = [:id, :status, :assigned_to_type, :parent_id, [:assigned_to, :type], :created_at]
    # col_labels = ["\#", "Status", "AssignToType", "P_ID", "ASGN_TO", "Created"]
    # puts appeal.tree(*atts, col_labels: col_labels)
    it "returns only specified column headings" do

    end

    # TaskTreeRender.treeconfig[:value_funcs_hash]["ASGN_TO.TYPE"] = ->(task) {
    #      TaskTreeRender.send_chain(task, [:assigned_to, :type])&.to_s || "" }
    # > puts appeal.tree(:id, :status, :assigned_to_type, "ASGN_TO.TYPE", :ASGN_BY, :ASGN_TO)
    it "returns column values that result from calling the specified lambda" do

    end

    # puts Task.find(8).tree(" ", :id, :status)
    it "highlights current task with an asterisk" do

    end
  end

  context ".tree is called on a task" do
    it "TBD" do

    end
  end

end

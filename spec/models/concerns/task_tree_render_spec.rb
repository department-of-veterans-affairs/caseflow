# frozen_string_literal: true

describe TaskTreeRender do
  before(:all) do
    @appeal = create(:appeal, :with_post_intake_tasks)
    root = @appeal.root_task
    create(:ama_judge_task, appeal: @appeal, parent: root, created_at: 1.day.ago)
    create(:ama_attorney_task, parent: root, appeal: @appeal)
    create(:ama_attorney_task, appeal: @appeal)
  end

  context ".tree is called on an appeal" do
    it "returns all tasks for the appeal" do
      # puts @appeal.tree
      rows_hash, metadata = @appeal.tree_hash
      expect(rows_hash.count).to eq 1
      expect(metadata.rows.count).to eq 6
    end

    it "returns only specified attributes" do
      _rows_hash, metadata = @appeal.tree_hash(:id, :status)
      expect(metadata.col_keys).to eq %w[id status]
    end

    it "returns dereferenced column chain '[:assigned_to, :type]'" do
      _rows_hash, metadata = @appeal.tree_hash(:id, [:assigned_to, :type])
      expect(metadata.col_keys).to eq ["id", "[:assigned_to, :type]"]
      @appeal.tasks.each do |t|
        expect(metadata.rows[t]["[:assigned_to, :type]"]).to eq t.assigned_to&.type if t.assigned_to.is_a?(Organization)
        expect(metadata.rows[t]["[:assigned_to, :type]"]).to eq "" if t.assigned_to.is_a?(User)
      end
    end

    it "uses specified column labels" do
      atts = [:id, :status, :assigned_to_type, :parent_id, [:assigned_to, :type], :created_at]
      col_labels = ["\#", "Status", "AssignToType", "P_ID", "ASGN_TO", "Created"]
      _rows_hash, metadata = @appeal.tree_hash(*atts, col_labels: col_labels)

      expect(metadata.col_keys).to eq ["id", "status", "assigned_to_type", "parent_id",
                                       "[:assigned_to, :type]", "created_at"]
      expect(metadata.col_metadata.values.pluck(:label)).to eq col_labels
    end

    it "returns column values that result from calling the specified lambda" do
      TaskTreeRender.treeconfig[:value_funcs_hash]["ASGN_TO.TYPE"] = lambda { |task|
        TaskTreeRender.send_chain(task, [:assigned_to, :type])&.to_s || ""
      }

      _rows_hash, metadata = @appeal.tree_hash(:id, :status, :assigned_to_type, "ASGN_TO.TYPE", :ASGN_BY, :ASGN_TO)
      @appeal.tasks.each do |t|
        expect(metadata.rows[t]["ASGN_TO.TYPE"]).to eq t.assigned_to&.type if t.assigned_to.is_a?(Organization)
        expect(metadata.rows[t]["ASGN_TO.TYPE"]).to eq "" if t.assigned_to.is_a?(User)
      end
    end
  end

  context ".tree is called on a task" do
    it "highlights self task with an asterisk" do
      task_to_highlight = @appeal.tasks.sample
      _rows_hash, metadata = task_to_highlight.tree_hash(" ", :id, :status)
      @appeal.tasks.each do |t|
        expect(metadata.rows[t][" "]).to eq "*" if t == task_to_highlight
        expect(metadata.rows[t][" "]).to eq " " unless t == task_to_highlight
      end
    end

    it "highlights specified task with an asterisk, even if no columns are specified" do
      task_to_highlight = @appeal.tasks.sample
      # puts @appeal.root_task.tree(highlight: task_to_highlight.id)

      _rows_hash, metadata = @appeal.root_task.tree_hash(highlight: task_to_highlight.id)
      @appeal.tasks.each do |t|
        expect(metadata.rows[t][" "]).to eq "*" if t == task_to_highlight
        expect(metadata.rows[t][" "]).to eq " " unless t == task_to_highlight
      end
    end

    it "highlights specified task with an asterisk, even if highlight column is not specified" do
      task_to_highlight = @appeal.tasks.sample
      # puts @appeal.root_task.tree(highlight: task_to_highlight.id)

      _rows_hash, metadata = @appeal.root_task.tree_hash(:id, :status, highlight: task_to_highlight.id)
      @appeal.tasks.each do |t|
        expect(metadata.rows[t][" "]).to eq "*" if t == task_to_highlight
        expect(metadata.rows[t][" "]).to eq " " unless t == task_to_highlight
      end
    end
  end
end

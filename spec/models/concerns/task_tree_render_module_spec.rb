# frozen_string_literal: true

describe TaskTreeRenderModule do
  let(:appeal) { create(:appeal, :with_post_intake_tasks) }
  let(:root_task) { appeal.root_task }
  let!(:ama_judge_assign_task) { create(:ama_judge_assign_task, parent: root_task, created_at: 1.day.ago.round) }
  let!(:ama_attorney_task) { create(:ama_attorney_task, parent: root_task) }
  let!(:task_no_parent) { create(:track_veteran_task, appeal: appeal) }

  context "#tree is called on an appeal" do
    it "returns all tasks for the appeal" do
      rows_hash, metadata = appeal.tree_hash
      expect(rows_hash.count).to eq 1
      expect(metadata.rows.count).to eq appeal.tasks.count
      expect(appeal.tree.lines.count).to eq appeal.tasks.count + 3
    end

    it "returns only specified attributes" do
      _rows_hash, metadata = appeal.tree_hash(:id, :status)
      expect(metadata.col_metadata.values.pluck(:label)).to eq %w[ID STATUS]
    end

    it "returns dereferenced column chain '[:assigned_to, :type]'" do
      _rows_hash, metadata = appeal.tree_hash(:id, [:assigned_to, :type])
      expect(metadata.col_metadata.values.pluck(:label)).to eq ["ID", "[:ASSIGNED_TO, :TYPE]"]
      appeal.tasks.each do |tsk|
        if tsk.assigned_to&.is_a?(Organization)
          expect(metadata.rows[tsk]["[:assigned_to, :type]"]).to eq tsk.assigned_to.type
        else
          expect(metadata.rows[tsk]["[:assigned_to, :type]"]).to eq ""
        end
      end
    end

    it "uses specified column labels" do
      atts = [:id, :status, :assigned_to_type, :parent_id, [:assigned_to, :type], :created_at]
      col_labels = ["\#", "Status", "AssignToType", "P_ID", "ASGN_TO", "Created"]
      _rows_hash, metadata = appeal.tree_hash(*atts, col_labels: col_labels)

      expect(metadata.col_metadata.values.pluck(:label)).to eq col_labels
    end

    it "returns column values that result from calling the specified lambda" do
      appeal.global_renderer.config.value_funcs_hash["ASGN_TO.TYPE"] = ->(task) { task.assigned_to.type }
      appeal.global_renderer.config.value_funcs_hash[:ASGN_TO_CSSID] = ->(task) { task.assigned_to.css_id }

      error_char = appeal.global_renderer.config.func_error_char
      _rows_hash, metadata = appeal.tree_hash(:id, :status, :assigned_to_type, "ASGN_TO.TYPE", :ASGN_BY, :ASGN_TO)
      appeal.tasks.each do |tsk|
        expect(metadata.rows[tsk]["ASGN_TO.TYPE"]).to eq tsk.assigned_to&.type if tsk.assigned_to.is_a?(Organization)
        expect(metadata.rows[tsk]["ASGN_TO.TYPE"]).to eq error_char if tsk.assigned_to.is_a?(User)
      end
    end
  end

  context "#tree is called on a task" do
    def check_for_highlight(metadata, task_to_highlight)
      highlight_char = appeal.global_renderer.config.highlight_char
      expect(metadata.rows[task_to_highlight][" "]).to eq highlight_char

      appeal.tasks.each do |tsk|
        expect(metadata.rows[tsk][" "]).to eq " " unless tsk == task_to_highlight
      end
    end

    it "highlights self task with an asterisk" do
      task_to_highlight = appeal.tasks.sample
      _rows_hash, metadata = task_to_highlight.tree_hash(" ", :id, :status)
      check_for_highlight(metadata, task_to_highlight)
    end

    it "highlights specified task with an asterisk, even if no columns are specified" do
      task_to_highlight = appeal.tasks.sample
      _rows_hash, metadata = appeal.root_task.tree_hash(highlight: task_to_highlight.id)
      check_for_highlight(metadata, task_to_highlight)
    end

    it "highlights specified task with an asterisk, even if highlight column is not specified" do
      task_to_highlight = appeal.tasks.sample
      appeal.global_renderer.config.default_atts = [:id, :status, :CLO_DATE, :CRE_TIME]

      _rows_hash, metadata = appeal.root_task.tree_hash(highlight: task_to_highlight.id)
      check_for_highlight(metadata, task_to_highlight)
    end
  end

  context "custom TaskTreeRenderer is used in functions" do
    def tree1(obj, *atts, **kwargs)
      kwargs[:renderer] ||= TaskTreeRenderModule.new_renderer
      kwargs[:renderer].tap do |r|
        r.compact_mode
        r.config.default_atts = [:id, :status, :ASGN_TO, :UPD_DATE]
      end
      obj.tree(*atts, **kwargs)
    end

    def tree2(obj, *atts, **kwargs)
      kwargs.delete(:renderer) && fail("Use `tree1` method to allow 'renderer' named parameter!")
      renderer = TaskTreeRenderModule.new_renderer.tap do |r|
        r.compact_mode
        r.config.default_atts = [:id, :status, :ASGN_TO, :UPD_DATE]
      end
      renderer.tree_str(obj, *atts, **kwargs)
    end

    it "prints all tasks" do
      num_lines = appeal.tasks.count + 1
      expect((tree1 appeal).lines.count).to eq num_lines
      expect((tree2 appeal, :id, :status).lines.count).to eq num_lines
    end
    it "should raise error" do
      expect { tree2 appeal, :id, :status, renderer: "any value" }.to raise_error(RuntimeError)
    end
  end

  context "appeal root-level changes" do
    it "shows new root-level task" do
      _, metadata = appeal.tree_hash
      expect(metadata.rows.count).to eq appeal.tasks.count
      initial_count = appeal.tasks.count + 3
      expect(appeal.tree.lines.count).to eq initial_count

      ama_judge_assign_task.cancelled!
      create(:ama_judge_assign_task, appeal: appeal, parent: nil, created_at: 1.day.ago.round)
      appeal.reload
      expect(appeal.tree.lines.count).to eq initial_count + 1
    end
    it "doesn't show deleted root-level task" do
      _, metadata = appeal.tree_hash
      expect(metadata.rows.count).to eq appeal.tasks.count
      initial_count = appeal.tasks.count + 3
      expect(appeal.tree.lines.count).to eq initial_count

      task_no_parent.delete
      appeal.reload
      expect(appeal.tree.lines.count).to eq initial_count - 1
    end
  end
end

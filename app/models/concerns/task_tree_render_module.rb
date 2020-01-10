# frozen_string_literal: true

# See instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRenderModule
  def treee(*atts, col_labels: nil, highlight: nil)
    puts tree(*atts, col_labels: col_labels, highlight: highlight)
  end

  @@ttrender = TaskTreeRender.new

  def tree(*atts, col_labels: nil, highlight: nil)
    @@ttrender.tree(self, *atts, col_labels: col_labels, highlight: highlight)
  end

  def tree_hash(*atts, col_labels: nil, highlight: nil)
    @@ttrender.tree_hash(self, *atts, col_labels: col_labels, highlight: highlight)
  end

end

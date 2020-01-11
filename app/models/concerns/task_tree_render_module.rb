# frozen_string_literal: true

# See instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRenderModule
  def default_tree_renderer
    @@default_renderer ||= TaskTreeRenderer.new
  end

  def treee(*atts, col_labels: nil, highlight: nil, renderer: default_tree_renderer)
    puts tree(*atts, col_labels: col_labels, highlight: highlight, renderer: renderer)
  end

  def tree(*atts, col_labels: nil, highlight: nil, renderer: default_tree_renderer)
    renderer.as_string(self, *atts, col_labels: col_labels, highlight: highlight)
  end

  def tree_hash(*atts, col_labels: nil, highlight: nil, renderer: default_tree_renderer)
    renderer.tree_hash(self, *atts, col_labels: col_labels, highlight: highlight)
  end
end

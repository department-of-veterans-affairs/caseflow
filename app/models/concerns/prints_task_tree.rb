# frozen_string_literal: true

module PrintsTaskTree
  extend ActiveSupport::Concern
  include TaskTreeRenderModule

  def structure_render(tasks, *atts)
    TTY::Tree.new(structure(tasks, *atts)).render
  end

  def structure(tasks, *atts)
    leaf_name = "#{self.class.name} #{task_tree_attributes(*atts)}"
    { "#{leaf_name}": task_tree_children(tasks).map { |child| child.structure(tasks, *atts) } }
  end

  def structure_as_json(tasks, *atts)
    leaf_name = self.class.name
    child_tree = task_tree_children(tasks).map { |child| child.structure_as_json(tasks, *atts) }
    { "#{leaf_name}": task_tree_attributes_as_json(*atts).merge(tasks: child_tree) }
  end

  private

  def task_tree_children(tasks)
    if is_a?(Task)
      tasks.select { |task| task.parent_id == id }.sort_by(&:id)
    else
      tasks.select { |task| task.parent_id.nil? }.sort_by(&:id)
    end
  end

  def task_tree_attributes(*atts)
    return attributes_to_s(*atts) if is_a? Task

    "#{id} [#{atts.join(', ')}]"
  end

  def task_tree_attributes_as_json(*atts)
    return attributes_to_h(*atts) if is_a? Task

    { id: id }
  end

  def attributes_to_h(*atts)
    atts.map { |att| [att, self[att]] }.to_h
  end

  def attributes_to_s(*atts)
    atts.map { |att| self[att].presence || "(#{att})" }.flatten.compact.join(", ")
  end
end

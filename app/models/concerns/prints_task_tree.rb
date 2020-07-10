# frozen_string_literal: true

module PrintsTaskTree
  extend ActiveSupport::Concern
  include TaskTreeRenderModule

  def structure_render(*atts)
    TTY::Tree.new(structure(*atts)).render
  end

  def structure(*atts)
    leaf_name = "#{self.class.name} #{task_tree_attributes(*atts)}"
    { "#{leaf_name}": task_tree_children.map { |child| child.structure(*atts) } }
  end

  def structure_as_json(*atts)
    leaf_name = self.class.name
    child_tree = task_tree_children.map { |child| child.structure_as_json(*atts) }
    { "#{leaf_name}": task_tree_attributes_as_json(*atts).merge(tasks: child_tree) }
  end

  private

  def task_tree_children
    return children.order(:id) if is_a? Task

    tasks.where(parent_id: nil).order(:id)
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

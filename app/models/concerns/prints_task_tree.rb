# frozen_string_literal: true

module PrintsTaskTree
  extend ActiveSupport::Concern
  include TaskTreeRenderModule

  def structure_render(*attrs)
    TTY::Tree.new(structure(*attrs)).render
  end

  def structure(*attrs)
    leaf_name = "#{self.class.name} #{task_tree_attributes(*attrs)}"
    { "#{leaf_name}": task_tree_children(*attrs).map { |child| child.structure(*attrs) } }
  end

  def structure_as_json(*attrs)
    leaf_name = self.class.name
    child_tree = task_tree_children(*attrs).map { |child| child.structure_as_json(*attrs) }
    { "#{leaf_name}": task_tree_attributes_as_json(*attrs).merge(tasks: child_tree) }
  end

  private

  def task_tree_children(*attrs)
    if is_a?(Task)
      attrs.first.select { |task| task.parent_id == id }.sort_by(&:id)
    else
      attrs.first.select { |task| task.parent_id.nil? }.sort_by(&:id)
    end
  end

  def task_tree_attributes(*attrs)
    return attributes_to_s(*attrs.last) if is_a? Task

    "#{id} [#{attrs.join(', ')}]"
  end

  def task_tree_attributes_as_json(*attrs)
    return attributes_to_h(*attrs.last) if is_a? Task

    { id: id }
  end

  def attributes_to_h(*attrs)
    attrs.map { |att| [att, self[att]] }.to_h
  end

  def attributes_to_s(*attrs)
    attrs.map { |att| self[att].presence || "(#{att})" }.flatten.compact.join(", ")
  end
end

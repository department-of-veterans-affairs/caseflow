class CorrespondenceTaskFilter < TaskFilter
  def filtered_tasks
    return tasks if where_clause.empty?
    # tasks.with_assignees.where(*where_clause)
  end
end

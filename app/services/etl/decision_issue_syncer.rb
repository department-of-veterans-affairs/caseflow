# frozen_string_literal: true

class ETL::DecisionIssueSyncer < ETL::Syncer
  def origin_class
    ::DecisionIssue
  end

  def target_class
    ETL::DecisionIssue
  end

  protected

  def instances_needing_update
    di_with_dec_doc = DecisionIssue.ama.includes(:ama_decision_documents).where.not(decision_documents: { created_at: nil})
      .select("*, 123444444444444 as aaa")

    Rails.logger.info("-=-==-==-=====--=-=-=-=-=-==-=-==")
    fields = DecisionIssue.column_names.map { |n| DecisionIssue.table_name + "." + n } +
             DecisionDocument.column_names.map { |n| DecisionDocument.table_name + "." + n + " AS dd__"+n } +
             Appeal.column_names.map { |n| Appeal.table_name + "." + n + " AS a__"+n }
            #  ["type", "status", "assigned_by_id", "assigned_to_id", "assigned_to_type"].map { |n| Task.table_name + "." + n }
    # AttorneyTask.last.dup.save(:validate => false)
    # AttorneyTask.last.dup.save(:validate => false)
    query = DecisionIssue.select(*fields.uniq, "123444444444444 as aaa").ama
      .includes(:ama_decision_documents).references(:decision_documents)
      .includes(:ama_appeal)
      # .includes(ama_appeal: :tasks)
      .joins("LEFT JOIN tasks as attorney_tasks ON attorney_tasks.appeal_id=decision_issues.decision_review_id AND attorney_tasks.appeal_type=decision_issues.decision_review_type AND attorney_tasks.type = 'AttorneyTask'")
      .joins("LEFT JOIN tasks as judge_review_tasks ON judge_review_tasks.appeal_id=decision_issues.decision_review_id AND judge_review_tasks.appeal_type=decision_issues.decision_review_type AND judge_review_tasks.type = 'JudgeDecisionReviewTask'")
      #.includes(Task.arel_table.alias(:attorney_tasks).to_sql)#.references(:attorney_tasks)
      #.includes(Task.arel_table.alias(:judge_review_tasks).to_sql) # .includes(:judge_review_tasks).references(:judge_review_tasks)
      #.references(:decision_issues)#.references(:decision_documents)
      .where.not(decision_documents: { created_at: nil})
      # .where(tasks: {type: [:JudgeDecisionReviewTask, :AttorneyTask]})
      # .group(*fields.uniq)
      # .group(*fields.uniq, "ama_appeals_decision_issues.id")
      # .group(*fields.uniq, "judge_review_tasks.assigned_to_id", "attorney_tasks.assigned_to_id")
      hash_result = query.pluck_to_hash(*fields.uniq)
      # hash_result = query.pluck_to_hash(*fields.uniq,
      # "STRING_AGG(judge_review_tasks.assigned_to_id::varchar, ',') as judge_ids", 
      # "STRING_AGG(attorney_tasks.assigned_to_id::varchar, ',') as attorney_ids")
    # query2 = DecisionIssue.select("*, judge_review_tasks.assigned_to_id as atty_id, attorney_tasks.assigned_to_id as judge_id").from("(#{query.to_sql}) as q1")
    #   .group(*fields.uniq)
    # hash_result = query2.pluck_to_hash(*fields.uniq,
    #   "STRING_AGG(atty_id::varchar, ',') as judge_ids", 
    #   "STRING_AGG(judge_id::varchar, ',') as attorney_ids")
    pp hash_result.map{|r| r.slice("decision_issues.id", "judge_ids", "attorney_ids")}
    di_with_dec_doc= query.select(*fields.uniq, "123 as a")
    # di_with_dec_doc= query.select(*fields.uniq,
    #   "STRING_AGG(judge_review_tasks.assigned_to_id::varchar, ',') as judge_ids", 
    #   "STRING_AGG(attorney_tasks.assigned_to_id::varchar, ',') as attorney_ids")
    binding.pry
    return di_with_dec_doc unless incremental?

    di_with_dec_doc.where("updated_at >= ?", since)
  end

  # private

  # def where_vha_request_issues(query)
  #   query.where(id: vha_appeal_ids)
  # end

  # def vha_appeal_ids
  #   RequestIssue.select(:decision_review_id).where(benefit_type: "vha", decision_review_type: :Appeal)
  # end
end

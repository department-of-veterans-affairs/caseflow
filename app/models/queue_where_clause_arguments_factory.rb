# frozen_string_literal: true

class QueueWhereClauseArgumentsFactory
  # ["col=docketNumberColumn&val=legacy,evidence_submission", "col=taskColumn&val=TranslationTask"]
  # ->
  # [
  #   "cached_appeals_attributes.docket_type IN (?) AND tasks.type in (?)",
  #   ["legacy", "evidence_submission"],
  #   ["TranslationTask"]
  # ]
  def self.from_params(filter_params = [])
    return [] if filter_params.empty?

    filters = filter_params.map { |filter_string| QueueFilterParameter.from_string(filter_string) }

    where_string = filters.map { |filter| "#{filter.column} IN (?)" }.join(" AND ")
    where_arguments = filters.map(&:values)

    [where_string] + where_arguments
  end
end

class JudgeCaseAssignment
  class << self
    attr_writer :repository

    def assign_to_attorney!(params)
      case params[:appeal_type]
      when "Legacy"
        vacols_id = Appeal.find(params[:appeal_id]).vacols_id
        MetricsService.record("VACOLS: assign_case_to_attorney #{vacols_id}",
                              service: :vacols,
                              name: "assign_case_to_attorney") do
          repository.assign_case_to_attorney!(
            judge: params[:assigned_by],
            attorney: params[:assigned_to],
            vacols_id: vacols_id
          )
        end
      end
    end

    def repository
      @repository ||= QueueRepository
    end
  end
end

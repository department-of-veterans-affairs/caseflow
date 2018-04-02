class CaseAssignment
  class << self
    attr_writer :repository

    def assign!(params)
      case params[:appeal_type]
      when "Legacy"
        repository.assign_case_to_attorney!(
          judge: params[:assigned_by],
          attorney: params[:assigned_to],
          vacols_id: Appeal.find(params[:appeal_id]).vacols_id
        )
      end
    end

    def repository
      @repository ||= QueueRepository
    end
  end
end

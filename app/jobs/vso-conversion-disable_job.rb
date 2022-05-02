# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class VSOConversionDisable < CaseflowJob
    def perform
    end
    def get_affected_appeals
    end
end

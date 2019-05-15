# frozen_string_literal: true

class PulacCurelloTask < GenericTask
    # Skip unique verification
    def verify_org_task_unique; end
  
    def label
      "Pulac Curello"
    end

    def default_assignee(_parent, _params)
        PulacCurello.singleton
    end
end

  
# frozen_string_literal: true

##
# Task that is assigned to a EduRegionalProcessingOffice organization for them to locate
# the appropriate documents for an appeal. 

class EduAssessDocumentationTask < Task
    validates :parent, presence: true,
                       on: :create
  
    # Actions that can be taken on both organization and user tasks
    DEFAULT_ACTIONS = [
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
      Constants.TASK_ACTIONS.READY_FOR_REVIEW.to_h
    ].freeze
  
    RPO_ACTIONS = [
      Constants.TASK_ACTIONS.EDU_REGIONAL_PROCESSING_OFFICE_RETURN_TO_EMO.to_h
    ].freeze

    def available_actions(user)
      return [] unless assigned_to.user_has_access?(user)
  
      task_actions = Array.new(DEFAULT_ACTIONS)
  
  
      if assigned_to.is_a?(EduRegionalProcessingOffice)
        task_actions.concat(RPO_ACTIONS)
      end
  
      ## TODO: create "mark task in progress" action
      # if appeal.tasks.in_progress.none? { |task| task.is_a?(EduAssessDocumentationTask) }
        # task_actions.concat([Constants.TASK_ACTIONS.EDU_MARK_TASK_IN_PROGRESS.to_h].freeze)
      # end
  
      task_actions
    end
  
    # def when_child_task_completed(child_task)
    #   append_instruction(child_task.instructions.last) if child_task.assigned_to.is_a?(VhaRegionalOffice)
  
    #   super
    # end
  
    def self.label
      COPY::ASSESS_DOCUMENTATION_TASK_LABEL
    end
  end
  
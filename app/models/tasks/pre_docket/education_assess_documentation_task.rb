# frozen_string_literal: true

##
# Task that is assigned to a EduRegionalProcessingOffice organization for them to locate
# the appropriate documents for an appeal. 

class EducationAssessDocumentationTask < Task
    validates :parent, presence: true,
                       on: :create
  
    TASK_ACTIONS = [
      # TODO
    ].freeze

    def available_actions(user)
      return [] unless assigned_to.user_has_access?(user)
  
      TASK_ACTIONS
    end

    def self.label
      COPY::ASSESS_DOCUMENTATION_TASK_LABEL
    end
  end
  
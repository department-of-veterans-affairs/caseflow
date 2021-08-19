# frozen_string_literal: true

# ETL:: service classes that need to know which ETL models are active.

module ETLClasses
  extend ActiveSupport::Concern

  ETL_SYNCER_KLASSES = %w[
    Appeal
    AttorneyCaseReview
    DecisionDocument
    DecisionIssue
    Hearing
    JudgeCaseReview
    LegacyHearing
    Organization
    OrganizationsUser
    Person
    RemandReason
    Task
    User
    VhaAppeal
    VhaHigherLevelReview
    VhaSupplementalClaim
  ].freeze

  class_methods do
    def syncer_klasses
      ETL_SYNCER_KLASSES.map { |klass| "ETL::#{klass}Syncer".constantize }
    end
  end

  def syncer_klasses
    self.class.syncer_klasses
  end
end

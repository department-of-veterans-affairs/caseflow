# frozen_string_literal: true

# ETL:: service classes that need to know which ETL models are active.

module ETLClasses
  extend ActiveSupport::Concern

  ETL_KLASSES = %w[
    Appeal
    AttorneyCaseReview
    DecisionIssue
    Hearing
    LegacyHearing
    Organization
    OrganizationsUser
    Person
    Task
    User
    VhaAppeal
    VhaHigherLevelReview
    VhaSupplementalClaim
  ].freeze

  class_methods do
    def syncer_klasses
      ETL_KLASSES.map { |klass| "ETL::#{klass}Syncer".constantize }
    end
  end

  def syncer_klasses
    self.class.syncer_klasses
  end
end

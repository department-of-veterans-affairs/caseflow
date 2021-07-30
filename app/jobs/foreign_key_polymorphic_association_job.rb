# frozen_string_literal: true

# This job exists to act as a foreign key for polymorphic associations
class ForeignKeyPolymporphicAssociationJob < CaseflowJob
  queue_with_priority :low_priority
end
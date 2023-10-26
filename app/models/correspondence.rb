# frozen_string_literal: true

# Correspondence is a top level object similar to Appeals.
# Serves as a collection of all data related to Correspondence workflow
class Correspondence < CaseflowRecord
  has_many :correspondence_documents
  has_many :correspondence_intakes
end

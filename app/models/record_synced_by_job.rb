# frozen_string_literal: true

class RecordSyncedByJob < ApplicationRecord
  belongs_to :record, polymorphic: true
end

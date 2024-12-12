# frozen_string_literal: true

class CorrespondencesAppealsTask < ApplicationRecord
  belongs_to :correspondence_appeal
  belongs_to :task
end

# frozen_string_literal: true

# This concern is used to identify appeals associated with the BEAAM program.
# Fulfills goal 2 of option 1 in the Tech Spec: Enable application code to identify BEAAM appeals.
# See https://github.com/department-of-veterans-affairs/caseflow/wiki/BEAAM-Appeals
# and Tech Spec https://github.com/department-of-veterans-affairs/caseflow/issues/16508
module BeaamAppealConcern
  extend ActiveSupport::Concern

  # Copied from https://github.com/department-of-veterans-affairs/caseflow/pull/8733/files
  BEAAM_CASE_IDS = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
                    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
                    50, 51,
                    53].freeze

  def beaam?
    BEAAM_CASE_IDS.include?(id) && Rails.env.production?
  end
end

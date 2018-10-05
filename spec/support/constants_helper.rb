# constants defined in client/ JS space are not easily accessible from Ruby space.
# ExecJS does not help us till ES6 syntax features are supported.

module ConstantsHelper
  INTAKE_FORM_RAMP_ELECTION = "RAMP Opt-In Election Form".freeze
  INTAKE_FORM_RAMP_REFILING = "RAMP Selection (VA Form 21-4138)".freeze
  INTAKE_FORM_HIGHER_LEVEL_REVIEW = "Decision Review Request: Higher-Level Review — VA Form 20-0996".freeze
  INTAKE_FORM_SUPPLEMENTAL_CLAIM = "Decision Review Request: Supplemental Claim — VA Form 20-0995".freeze
  INTAKE_FORM_APPEAL = "Decision Review Request: Board Appeal (Notice of Disagreement) — VA Form 10182".freeze
end

# frozen_string_literal: true

class IntakesFlaggedForManagerReviewQuery
  def self.call
    Intake.select("intakes.*, intakes.type as form_type, users.full_name")
      .joins(:user,
             # Exclude an intake from results if an intake with the same veteran_file_number
             # and intake type has succeeded since the completed_at time (indicating the issue has been resolved)
             "LEFT JOIN
               (SELECT veteran_file_number,
                 type,
                 MAX(completed_at) as succeeded_at
               FROM intakes
               WHERE completion_status = 'success'
               GROUP BY veteran_file_number, type) latest_success
               ON intakes.veteran_file_number = latest_success.veteran_file_number
               AND intakes.type = latest_success.type",
             # To exclude ramp elections that were established outside of Caseflow
             "LEFT JOIN ramp_elections ON intakes.veteran_file_number = ramp_elections.veteran_file_number")
      .where.not(completion_status: "success")
      .where(error_code: [nil, "veteran_not_accessible", "veteran_not_valid"])
      .where(
        "(intakes.completed_at > latest_success.succeeded_at OR latest_success.succeeded_at IS NULL)
        AND NOT (intakes.type = 'RampElectionIntake' AND ramp_elections.established_at IS NOT NULL)"
      )
  end
end

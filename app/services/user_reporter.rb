# frozen_string_literal: true

# builds a profile of a user's footprint across Caseflow.
# Originally for de-duping user records but can be used more generally
# to report on a user's activity.
class UserReporter
  attr_reader :user_ids
  cattr_accessor :models_with_user_id

  def initialize(css_id)
    @css_id = coerce_css_id(css_id)
    @user_ids = []
  end

  def report
    report = []
    all_users_for_css_id.each do |user|
      user_ids << user.id
      report << report_user_related_records(user)
    end
    report.flatten
  end

  private

  attr_reader :css_id
  attr_writer :user_ids

  def coerce_css_id(css_id)
    css_id.is_a?(User) ? css_id.css_id : css_id
  end

  # rubocop:disable Metrics/MethodLength
  def models_with_named_user_foreign_key
    [
      { model: AttorneyCaseReview, column: :attorney },
      { model: AttorneyCaseReview, column: :reviewing_judge },
      { model: Distribution, column: :judge },
      { model: HearingDay, column: :judge },
      { model: HearingDay, column: :created_by },
      { model: HearingDay, column: :updated_by },
      { model: Hearing, column: :judge },
      { model: Hearing, column: :created_by },
      { model: Hearing, column: :updated_by },
      { model: JudgeCaseReview, column: :judge },
      { model: JudgeCaseReview, column: :attorney },
      { model: LegacyHearing, column: :created_by },
      { model: LegacyHearing, column: :updated_by },
      { model: Task, column: :assigned_by },
      { model: Task, column: :assigned_to },
      { model: AppealView, column: :user, unique: [:appeal_type, :appeal_id] },
      { model: HearingView, column: :user, unique: [:hearing_type, :hearing_id] },
      { model: DocumentView, column: :user, unique: [:document_id] },
      { model: UserQuota, column: :user, unique: [:team_quota_id] }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def models_with_user_id
    self.class.models_with_user_id ||= [
      AdvanceOnDocketMotion, Annotation, AppealIntake,
      Certification, ClaimReviewIntake, ClaimsFolderSearch,
      DecisionReviewIntake, Dispatch::Task,
      EndProductEstablishment, EstablishClaim,
      HigherLevelReviewIntake,
      Intake,
      JudgeSchedulePeriod,
      LegacyHearing,
      OrganizationsUser,
      RampElectionIntake, RampElectionRollback, RampRefilingIntake, RequestIssuesUpdate,
      RoSchedulePeriod,
      SchedulePeriod, SupplementalClaimIntake
    ].map { |cls| { model: cls, column: :user_id } }
  end

  def report_user_related_records(user)
    related_records = []

    (models_with_user_id + models_with_named_user_foreign_key).each do |foreign_key|
      num = foreign_key[:model].where(foreign_key[:column] => user).count
      if num > 0
        related_records << "#{user.id} has #{num} #{foreign_key[:model]}.#{foreign_key[:column]}"
      end
    end

    related_records
  end

  # UPPER(css_id) is unique, so this should always return 1 or 0 records
  def all_users_for_css_id
    User.where("UPPER(css_id)=UPPER(?)", css_id)
  end
end

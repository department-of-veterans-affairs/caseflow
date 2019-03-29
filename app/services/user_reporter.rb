# frozen_string_literal: true

# builds a profile of a user's footprint across Caseflow.
# Originally for de-duping user records but can be used more generally
# to report on a user's activity.
class UserReporter
  attr_accessor :css_id
  attr_accessor :user_ids
  cattr_accessor :models_with_user_id

  def initialize(css_id)
    @css_id = css_id.is_a?(User) ? css_id.css_id : css_id
  end

  def report
    report = []
    @user_ids = []
    all_users_for_css_id.each do |user|
      @user_ids << user.id
      report << report_user_related_records(user)
    end
    report.flatten
  end

  def merge_all_users_with_uppercased_user
    User.transaction do
      other_users = all_users_for_css_id - [uppercase_user]

      other_users.each do |user|
        replace_user(user, uppercase_user)
        user.delete
      end
    end
  end

  private

  def models_with_named_user_foreign_key
    [
      { model: AttorneyCaseReview, column: :attorney },
      { model: AttorneyCaseReview, column: :reviewing_judge },
      { model: Distribution, column: :judge },
      { model: HearingDay, column: :judge },
      { model: Hearing, column: :judge },
      { model: JudgeCaseReview, column: :judge },
      { model: JudgeCaseReview, column: :attorney },
      { model: Task, column: :assigned_by },
      { model: Task, column: :assigned_to },
      { model: AppealView, column: :user, unique: [:appeal_type, :appeal_id] },
      { model: HearingView, column: :user, unique: [:hearing_type, :hearing_id] },
      { model: DocumentView, column: :user, unique: [:document_id] },
      { model: ReaderUser, column: :user, unique: [] },
      { model: UserQuota, column: :user, unique: [:team_quota_id] }
    ]
  end

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

  def delete_unique_constraint_violating_records(scope, foreign_key, fk_column_name, old_user, new_user)
    return unless foreign_key[:unique]

    if foreign_key[:unique].empty?
      scope.where(fk_column_name => old_user.id).delete_all
    else
      existing_unique_fields = scope.where(fk_column_name => new_user.id).pluck(*foreign_key[:unique])

      if !existing_unique_fields.empty?
        # This query inspired by https://stackoverflow.com/questions/15750234/ruby-activerecord-and-sql-tuple-support
        scope
          .where(
            "(#{foreign_key[:unique].join(', ')}) IN (#{(['(?)'] * existing_unique_fields.size).join(', ')})",
            *existing_unique_fields
          ).where(fk_column_name => old_user.id).delete_all
      end
    end
  end

  def replace_user(old_user, new_user)
    (models_with_user_id + models_with_named_user_foreign_key).map do |foreign_key|
      column_id_name = "#{foreign_key[:column]}_id".to_sym
      column_type_name = "#{foreign_key[:column]}_type".to_sym
      model_col_names = foreign_key[:model].column_names.map(&:to_sym)

      fk_column_name = model_col_names.include?(column_id_name) ? column_id_name : foreign_key[:column]

      scope = if model_col_names.include?(column_type_name)
                foreign_key[:model].where(column_type_name => "User")
              else
                foreign_key[:model]
              end

      delete_unique_constraint_violating_records(scope, foreign_key, fk_column_name, old_user, new_user)

      scope.where(fk_column_name => old_user.id).update(fk_column_name => new_user.id)
    end
  end

  def all_users_for_css_id
    User.where("UPPER(css_id)=UPPER(?)", css_id)
  end

  def uppercase_user
    User.find_by(css_id: css_id.upcase)
  end
end

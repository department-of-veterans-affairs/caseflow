# frozen_string_literal: true

# builds a profile of a user's footprint across Caseflow.
# Originally for de-duping user records but can be used more generally
# to report on a user's activity.
class UserReporter
  attr_accessor :css_id
  attr_accessor :user_ids
  cattr_accessor :models_with_user_id

  def initialize(css_id)
    @css_id = css_id
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
    uppercase_user = User.find_by(css_id: css_id.upcase)

    other_users = all_users_for_css_id - uppercase_user

    reassigned_users = other_users.map do |user|
      {
        create_associations: replace_user_id(user.id, uppercase_user.id),
        create_user: "User.create(#{user.to_hash})"
      }
    end

    uppercase_user.update!(undo_transform: reassigned_users)
    other_users.delete_all!
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
      { model: Task, column: :assigned_to }
    ]
  end

  # when run from a rake task in production, must load models explicitly.
  def load_all_models
    ::Rails.application.eager_load!
  end

  def models_with_user_id
    load_all_models unless self.class.models_with_user_id
    self.class.models_with_user_id ||= ActiveRecord::Base.descendants.reject(&:abstract_class?)
      .select { |c| c.attribute_names.include?("user_id") }.uniq
  end

  def replace_user_id(old_id, new_id)
    undo_actions = []

    models_with_user_id.each do |cls|
      undo_actions << "#{cls}.where(id: #{cls.where(user_id: old_id).pluck(:id)}).update!(user_id: old_id)"
      cls.where(user_id: old_id).update!(user_id: new_id)
    end

    models_with_named_user_foreign_key.each do |foreign_key|
      ids = cls.where(foreign_key[:column] => user).pluck(:id)
      undo_actions << "#{foreign_key[:model]}.where(id: #{ids}).update!(#{(foreign_key[:column].to_s+"_id").to_sym} => old_id)"
      foreign_key[:model].where(foreign_key[:column] => user).update!((foreign_key[:column].to_s+"_id").to_sym => new_id)
    end

    undo_actions
  end

  def report_user_related_records(user)
    related_records = []
    models_with_user_id.each do |cls|
      num = cls.where(user_id: user.id).count
      if num > 0
        related_records << "#{user.id} has #{num} #{cls}"
      end
    end

    models_with_named_user_foreign_key.each do |foreign_key|
      num = foreign_key[:model].where(foreign_key[:column] => user).count
      if num > 0
        related_records << "#{user.id} has #{num} #{foreign_key[:model]}.#{foreign_key[:column]}"
      end
    end

    related_records
  end

  def all_users_for_css_id
    User.where("UPPER(css_id)=UPPER(?)", css_id)
  end
end

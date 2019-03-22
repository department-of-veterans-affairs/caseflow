# frozen_string_literal: true

# builds a profile of a user's footprint across Caseflow.
# Originally for de-duping user records but can be used more generally
# to report on a user's activity.
class UserDedupService
  attr_accessor :user
  cattr_accessor :models_with_user_id

  def initialize(user)
    @user = user
  end

  def undo_change
    return if user.undo_record_merging.nil?

    User.transaction do
      user.undo_record_merging.each do |undo_merge|
        User.create(
          undo_merge["create_user"].except!("display_name")
        )

        undo_merge["create_associations"].each do |association|
          (Object.const_get association["model"]).where(id: association["ids"]).update(association["column"] => association["user_id"])
        end
      end

      user.update(undo_record_merging: nil)
    end
  end

  def merge_all_users_with_uppercased_user
    User.transaction do
      uppercase_user = User.find_by(css_id: user.css_id.upcase)

      other_users = all_users_for_css_id - [uppercase_user]

      reassigned_users = other_users.map do |user|
        {
          create_associations: replace_user(user, uppercase_user),
          create_user: user.to_hash
        }
      end

      uppercase_user.update(undo_record_merging: ((uppercase_user.undo_record_merging || []) + reassigned_users))
      other_users.each(&:delete)
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
      .map { |cls| { model: cls, column: :user } }
  end

  def replace_user(old_user, new_user)
    (models_with_user_id + models_with_named_user_foreign_key).map do |foreign_key|
      column_id_name = "#{foreign_key[:column]}_id".to_sym
      column_type_name = "#{foreign_key[:column]}_type".to_sym

      scope = if foreign_key[:model].column_names.include?(column_type_name)
                foreign_key[:model].where(column_id_name => old_user.id).where(column_type_name => "User")
              else
                foreign_key[:model].where(column_id_name => old_user.id)
              end

      undo_action = {
        model: foreign_key[:model].name,
        column: column_id_name,
        ids: scope.pluck(:id),
        user_id: old_user.id
      }
      scope.update(column_id_name => new_user.id)

      undo_action
    end
  end

  def all_users_for_css_id
    User.where("UPPER(css_id)=UPPER(?)", user.css_id)
  end
end

class ChangeCssLimit < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      change_column :appeals, :claimant_participant_id, :string, limit: 50
      change_column :attorney_case_reviews, :attorney_css_id, :string, limit: 50
      change_column :attorney_case_reviews, :reviewing_judge_css_id, :string, limit: 50
      change_column :hearings, :created_by_user_css_id, :string, limit: 50
      change_column :hearings, :hearing_day_created_by_user_css_id, :string, limit: 50
      change_column :hearings, :hearing_day_updated_by_user_css_id, :string, limit: 50
      change_column :hearings, :updated_by_user_css_id, :string, limit: 50
      change_column :people, :participant_id, :string, limit: 50
      change_column :tasks, :assigned_by_user_css_id, :string, limit: 50
      change_column :tasks, :assigned_to_user_css_id, :string, limit: 50
      change_column :users, :css_id, :string, limit: 50
    end
  end

  def down
    safety_assured do
      change_column :appeals, :claimant_participant_id, :string, limit: 20
      change_column :attorney_case_reviews, :attorney_css_id, :string, limit: 20
      change_column :attorney_case_reviews, :reviewing_judge_css_id, :string, limit: 20
      change_column :hearings, :created_by_user_css_id, :string, limit: 20
      change_column :hearings, :hearing_day_created_by_user_css_id, :string, limit: 20
      change_column :hearings, :hearing_day_updated_by_user_css_id, :string, limit: 20
      change_column :hearings, :updated_by_user_css_id, :string, limit: 20
      change_column :people, :participant_id, :string, limit: 20
      change_column :tasks, :assigned_by_user_css_id, :string, limit: 20
      change_column :tasks, :assigned_to_user_css_id, :string, limit: 20
      change_column :users, :css_id, :string, limit: 20
    end
  end
end

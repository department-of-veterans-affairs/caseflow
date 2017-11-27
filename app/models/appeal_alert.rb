class AppealAlert
  include ActiveModel::Model

  attr_accessor :appeal, :type

  def to_hash
    { type: type, details: details }
  end

  private

  def details
    case type
    when :form9_needed
      { due_date: appeal.form9_due_date }
    when :scheduled_hearing
      hearing = appeal.scheduled_hearings.sort_by(&:date).first
      {
        date: hearing.date.to_date,
        type: hearing.type
      }
    when :hearing_no_show
      due_date = appeal.hearings
                       .select(&:no_show?)
                       .map(&:no_show_excuse_letter_due_date)
                       .max
      { due_date: due_date }
    when :held_for_evidence
      due_date = appeal.hearings
                       .select(&:held_open?)
                       .map(&:hold_release_date)
                       .max
      { due_date: due_date }
    when :cavc_option
      { due_date: appeal.cavc_due_date }
    else
      {}
    end
  end
end

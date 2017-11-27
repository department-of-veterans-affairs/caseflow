class AppealAlerts
  include ActiveModel::Model

  attr_accessor :appeal

  def all
    [
      form9_needed,
      scheduled_hearing,
      hearing_no_show,
      held_for_evidence,
      cavc_option
    ].compact
  end

  private

  def form9_needed
    if appeal.api_status == :pending_form9 && Date.today <= appeal.form9_due_date
      AppealAlert.new(appeal: appeal, type: :form9_needed)
    end
  end

  def scheduled_hearing
    if appeal.api_status == :scheduled_hearing
      AppealAlert.new(appeal: appeal, type: :scheduled_hearing)
    end
  end

  def hearing_no_show
    if appeal.api_status == :on_docket
      recent_missed_hearing = appeal.hearings.find do |hearing|
        hearing.no_show? && Date.today <= hearing.no_show_excuse_letter_due_date
      end

      AppealAlert.new(appeal: appeal, type: :hearing_no_show) if recent_missed_hearing
    end
  end

  def held_for_evidence
    if appeal.api_status == :on_docket
      hearing_with_pending_hold = appeal.hearings.find do |hearing|
        hearing.held_open? && Date.today <= hearing.hold_release_date
      end

      AppealAlert.new(appeal: appeal, type: :held_for_evidence) if hearing_with_pending_hold
    end
  end

  def cavc_option
    if appeal.api_status == :bva_decision && Date.today <= appeal.cavc_due_date
      AppealAlert.new(appeal: appeal, type: :cavc_option)
    end
  end
end

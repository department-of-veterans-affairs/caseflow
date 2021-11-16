# frozen_string_literal: true

# Metric ID: B909040940
# Metric definition:  decided legacy appeal count with an AppealView + decided AMA appeal count with an AppealView
#                    ----------------------------------------------------------------------------------------------
#                                        decided legacy appeal count + decided AMA appeal count

class Metrics::ReaderAdoptionRate < Metrics::Base
  def call
    ama_appeal_ids = all_decided_appeal_ids("Appeal")
    legacy_appeal_ids = all_decided_appeal_ids("LegacyAppeal")

    ama_appeals_with_views_ids = appeal_ids_with_reader_views("Appeal", ama_appeal_ids)
    legacy_appeals_with_views_ids = appeal_ids_with_reader_views("LegacyAppeal", legacy_appeal_ids)

    (legacy_appeals_with_views_ids.count + ama_appeals_with_views_ids.count) /
      (legacy_appeal_ids.count + ama_appeal_ids.count).to_f
  end

  def name
    "Reader Adoption Rate"
  end

  def id
    "B909040940"
  end

  private

  def all_decided_appeal_ids(appeal_type)
    DecisionDocument.where(
      "appeal_type = ? and decision_date >= ? and decision_date <= ?", appeal_type, start_date, end_date
    ).pluck(:appeal_id).uniq
  end

  def appeal_ids_with_reader_views(appeal_type, ids)
    AppealView.where("appeal_type = ? and appeal_id in (?)", appeal_type, ids).pluck(:appeal_id).uniq
  end
end

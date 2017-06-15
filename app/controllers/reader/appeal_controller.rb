class Reader::AppealController < ApplicationController
  def index
    respond_to do |format|
      format.html { return render(:index) }
      format.json do
        MetricsService.record "Get assignments for #{current_user.vacols_id}" do
          render json: {
            cases: appeals
          }
        end
      end
    end
  end

  def logo_name
    "Reader"
  end

  def appeals
    appeals = current_user.current_case_assignments

    appeal_ids = appeals.map(&:id)
    opened_appeals_hash = current_user.appeal_views.where(appeal_id: appeal_ids)
                            .each_with_object({}) do |appeal_view, object|
      object[appeal_view.appeal_id] = true
    end

    appeals.map do |appeal|
      appeal.serializable_hash(
        methods: [:veteran_full_name]
      ).tap do |hash|
        hash[:viewed] = opened_appeals_hash[appeal.id]
      end
    end
  end

  def logo_path
    reader_appeal_index_path
  end
end
class WorkQueue::BespokeTaskSerializer
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.serialize(task, options = {})
    {
      id: task.id.to_s,
      type: "#{task.class.name}s".underscore,
      attributes: {
        is_legacy: false,
        type: task.type,
        label: task.label,
        appeal_id: task.appeal_id,
        status: task.status,
        assigned_at: task.assigned_at,
        started_at: task.started_at,
        completed_at: task.completed_at,
        placed_on_hold_at: task.placed_on_hold_at,
        on_hold_duration: task.on_hold_duration,
        instructions: task.instructions,
        appeal_type: task.appeal_type,
        assigned_by: {
          first_name: task.assigned_by_display_name.first,
          last_name: task.assigned_by_display_name.last,
          css_id: task.assigned_by.try(:css_id),
          pg_id: task.assigned_by.try(:id)
        },
        assigned_to: {
          css_id: task.assigned_to.try(:css_id),
          type: task.assigned_to.class.name,
          id: task.assigned_to.id
        },
        docket_name: task.appeal.try(:docket_name),
        case_type: task.appeal.try(:type),
        docket_number: task.appeal.try(:docket_number),
        veteran_full_name: task.appeal.veteran_full_name,
        veteran_file_number: task.appeal.veteran_file_number,
        external_appeal_id: task.appeal.external_id,
        aod: task.appeal.try(:advanced_on_docket),
        issue_count: task.appeal.number_of_issues,
        previous_task: { assigned_at: task.previous_task.try(:assigned_at) },
        document_id: task.latest_attorney_case_review ? task.latest_attorney_case_review.document_id : nil,
        decision_prepared_by: {
          first_name: task.prepared_by_display_name ? task.prepared_by_display_name.first : nil,
          last_name: task.prepared_by_display_name ? task.prepared_by_display_name.last : nil
        },
        available_actions: task.available_actions_unwrapper(options[:user]),
        task_business_payloads: task.task_business_payloads.map do |payload|
          { description: payload.description, values: payload.values }
        end
      }
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end

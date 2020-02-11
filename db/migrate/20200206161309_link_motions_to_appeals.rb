class LinkMotionsToAppeals < ActiveRecord::Migration[5.1]
  def up
    # Index creation and task_id removal will be a separate Caseflow::Migration
    add_reference :post_decision_motions, :appeal, foreign_key: true, index: false
    safety_assured do
      execute <<-EOS.strip_heredoc
        UPDATE post_decision_motions SET appeal_id = (
          SELECT appeals.id FROM appeals
            WHERE (
                (stream_type = 'Original' AND disposition IN ('denied', 'dismissed')) OR
                (stream_type = 'Vacate' AND disposition IN ('granted', 'partially_granted'))
              ) AND
              appeals.stream_docket_number = (
                SELECT appeals.stream_docket_number
                  FROM tasks JOIN appeals ON tasks.appeal_id = appeals.id
                  WHERE tasks.id = post_decision_motions.task_id
            )
            LIMIT 1
        )
      EOS
    end
  end

  def down
    safety_assured do
      execute <<-EOS.strip_heredoc
        UPDATE post_decision_motions SET task_id = (
          SELECT tasks.id
            FROM tasks JOIN appeals ON tasks.appeal_id = appeals.id
            WHERE
              tasks.type = 'JudgeAddressMotionToVacateTask' AND
              appeals.stream_type = 'Original' AND
              appeals.stream_docket_number = (
                SELECT appeals.stream_docket_number FROM appeals
                  WHERE appeals.id = post_decision_motions.appeal_id
              )
            LIMIT 1
        )
      EOS
      remove_reference :post_decision_motions, :appeal, foreign_key: true
    end
  end
end

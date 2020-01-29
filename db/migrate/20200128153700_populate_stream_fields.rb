class PopulateStreamFields < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      change_table :appeals do |t|
        t.change_default :stream_type, "Original"
      end
      execute "UPDATE appeals SET stream_type='Original' WHERE stream_type IS NULL"
      execute <<-EOS.strip_heredoc
        UPDATE appeals
          SET stream_docket_number=to_char(receipt_date, 'YYMMDD-') || id
          WHERE stream_docket_number IS NULL AND receipt_date IS NOT NULL
      EOS
    end
  end

  # Previous to https://github.com/department-of-veterans-affairs/caseflow/issues/13211
  # which includes this backfill, the stream_docket_number and stream_type fields were
  # not used. Therefore, nothing needs to happen in order to rollback the migration.
  def down; end
end

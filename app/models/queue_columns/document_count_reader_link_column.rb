# frozen_string_literal: true

class DocumentCountReaderLinkColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.DOCUMENT_COUNT_READER_LINK_COLUMN
  end
end

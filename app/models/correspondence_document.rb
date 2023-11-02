# frozen_string_literal: true

class CorrespondenceDocument < CaseflowRecord
  belongs_to :correspondence

  # remove after implementing fetch from S3
  def fetch_document
    if FeatureToggle.enabled?(:correspondence_queue)
      file = File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf")
      file
    end
  end
end

# frozen_string_literal: true

class CorrespondenceDocument < CaseflowRecord
  belongs_to :correspondence

  def fetch_content
    if FeatureToggle.enabled?(:correspondence_queue)
      file = File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf")
      content = File.read(file)
      content
    end
  end
end

# frozen_string_literal: true

class CorrespondenceRootTask < CorrespondenceTask
  # if self.status=="on_hold"
  #   def task_url
  #     "/test"
  #   end
  # end
  def task_url
    # this returns nil if the task status is not completed... unsure what is expected behavior
    if self.status=="completed"
      "/under_construction"
    end
  end
end

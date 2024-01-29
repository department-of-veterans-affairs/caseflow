# frozen_string_literal: true

class EfolderUploadFailedTask < ReviewPackageTask

  def task_url
    if self.parent.is_a?(ReviewPackageTask)
      "/queue/correspondence/#{self.correspondence.uuid}/review_package"
    elseif self.parent.is_a?(CorrespondenceIntakeTask)
      "/queue/correspondence/#{self.correspondence.uuid}/intake"
    end
  end
end

# frozen_string_literal: true

##
# Allows a Correspondence to respond to Appeal methods
#
# Ultimately, probably need to revisit the inheritance hierarchy here and give these models a common ancestor
# or something
module AppealableCorrespondence
  extend ActiveSupport::Concern

  def active?
    true
  end

  def cavc?
    true
  end

  def open_cavc_task
    true
  end

  def root_task
    Task.find_by(appeal_id: id, appeal_type: type, type: CorrespondenceRootTask.name)
  end
end

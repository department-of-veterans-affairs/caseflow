# frozen_string_literal: true

class AppealsForReaderJob
  def initialize(user)
    @user = user
  end

  def process
    # Not all legacy tasks are stored in Caseflow so search through Vacols first
    appeals = user.current_case_assignments

    # We'd like to grab all appeals that are either assigned, in-progress or on-hold
    # Correspondence Tasks will return Correspondences as an appeal, so we will filter these out
    appeals += Task.active
      .where(assigned_to: user)
      .map(&:appeal).uniq
      .filter { |appeal| !appeal.is_a?(Correspondence) }

    # Attorney legacy tasks are not yet stored in Caseflow tasks. However, we can grab
    # the ones "on hold" by looking for colocated tasks they have assigned
    if user.attorney_in_vacols?
      appeals += ColocatedTask.active.where(assigned_by: user).map(&:appeal).uniq
    end
    appeals
  end

  private

  attr_reader :user
end

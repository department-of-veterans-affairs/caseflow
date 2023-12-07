# frozen_string_literal: true

class ReassignPackageTask < ReviewPackageTask
  def self.label
    "Reassign Package Task"
  end

  def available_actions(user)
    print('hi')
  end
end

# frozen_string_literal: true

class MailTaskController < ApplicationController
  def create
    binding.pry
    Task.create!(
      type: type,
      appeal: appeal,
      assigned_by_id: user.id,
      parent_id: id,
      assigned_to: PulacCurello.singleton
    )
  end

  def mail_task_params
    binding.pry
    params.require("task", "appeal", "user").permit
  end
end

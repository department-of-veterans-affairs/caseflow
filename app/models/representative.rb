# frozen_string_literal: true

class Representative < Organization
  after_initialize :set_role

  def can_receive_task?(_task)
    false
  end

  def should_write_ihp?(appeal)
    ihp_writing_configs.include?(appeal.docket_type) && appeal.vsos.include?(self)
  end

  private

  def set_role
    self.role = "VSO"
  end

  def ihp_writing_configs
    vso_config&.ihp_dockets || default_ihp_dockets
  end

  def default_ihp_dockets
    []
  end
end

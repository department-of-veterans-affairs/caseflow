# frozen_string_literal: true

class PrivateBar < Representative
  def should_write_ihp?(_appeal)
    false
  end
end

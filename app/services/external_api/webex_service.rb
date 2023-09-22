# frozen_string_literal: true

class ExternalApi::WebexService
  def create_conference(*)
    fail NotImplementedError
  end

  def delete_conference(*)
    fail NotImplementedError
  end

  private

  def error?
    [].include? @status_code
  end
end

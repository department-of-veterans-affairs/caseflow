class FormResponse
  def initialize(success:, errors:, extra: {})
    @success = success
    @errors = errors.to_ary
    @extra = extra
  end

  attr_reader :errors, :extra

  def success?
    @success
  end

  def to_h
    { success: success, errors: errors }.merge!(extra)
  end

  private

  attr_reader :success
end

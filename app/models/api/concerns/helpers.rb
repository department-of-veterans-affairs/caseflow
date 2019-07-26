module Api::Helpers
  extend ActiveSupport::Concern

  private

  # returns a valid int or nil. for avoiding to_i which fails with 0
  def to_int val
    Integer val
  rescue
    nil
  end

  def join_present(*args)
    args.reject(&:blank?).join(" ")
  end
end

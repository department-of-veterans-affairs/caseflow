# frozen_string_literal: true

class CaseflowLogger
  DEFAULTS = { level: :info }.freeze

  LEVELS = %w[debug info warn error].map(&:to_sym)

  def self.log(log_name, **params)
    level = determine_log_level(**params)
    params.delete(:level)
    message = build_message(log_name, **params)

    Rails.logger.send(level, message)
  end

  private

  def self.determine_log_level(**params)
    (params.key?(:level) && params[:level].to_sym.in?(LEVELS)) ? params[:level].to_sym : :info
  end

  def self.build_message(log_name, **params)
    params = params.map { |args| format_param(args[0], args[1]) }
    log_name + " " + params.join(" ")
  end

  def self.format_param(key, value)
    key = key.to_s.gsub(/[^\w]/i, " ").downcase
    value = value.to_s.delete('"', "")
    "#{key}=\"#{value}\""
  end
end

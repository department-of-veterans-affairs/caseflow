# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do
    # oracle-enhanced v6.00 changes the default sequence start value from 10,000 to 1:
    #   Release Notes: https://github.com/rsim/oracle-enhanced/blob/v6.0.6/History.md#600--2019-08-17
    #   Related PR: https://github.com/rsim/oracle-enhanced/pull/1636
    #
    # Preserve the original default value of 10,000
    self.default_sequence_start_value = 10_000
  end
end

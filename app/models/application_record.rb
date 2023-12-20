# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # this simple transform should match the basic ActiveRecord::Result format
  # for db results.
  def as_hash
    as_json.with_indifferent_access.tap do |rec|
      rec.transform_values! do |value|
        if value.is_a?(Time) || value.is_a?(DateTime)
          ymdhms = value.utc.strftime("%Y-%m-%d %H:%M:%S")
          subseconds = value.utc.strftime(".%6N").to_f.to_s.sub(/^0\./, "")
          "#{ymdhms}.#{subseconds}"
        else
          value.as_json
        end
      end
    end
  end
end

# :nocov:
# Helper for multi-database transactions
# http://technology.customink.com/blog/2015/06/22/rails-multi-database-best-practices-roundup/
ActiveRecord::Base.class_eval do
  def self.multi_transaction
    ActiveRecord::Base.transaction do
      VACOLS::Record.transaction { yield }
    end
  end

  def multi_transaction
    self.class.multi_transaction { yield }
  end
end
# :nocov:

# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
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

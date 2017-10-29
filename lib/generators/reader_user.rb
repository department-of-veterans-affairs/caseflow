class Generators::ReaderUser
  extend Generators::Base
  class << self
    def default_attrs
      {
        user_id: nil,
        appeals_docs_fetched_at: nil
      }
    end

    def build(attrs = {})
      ReaderUser.new(default_attrs.merge(attrs))
    end
  end
end

class Generators::ReaderUser
  extend Generators::Base
  class << self
    def default_attrs
      {
        user_id: nil,
        current_appeals_documents_fetched_at: nil
      }
    end

    def build(attrs = {})
      ReaderUser.new(default_attrs.merge(attrs))
    end
  end
end

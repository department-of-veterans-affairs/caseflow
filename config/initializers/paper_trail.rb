PaperTrail.config.track_associations = false
PaperTrail::Rails::Engine.eager_load!

module PaperTrail
  class Version < ActiveRecord::Base
    def user
      # rubocop:disable Style/RedundantSelf
      User.find(self.whodunnit.to_i)
    end
  end
end

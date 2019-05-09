PaperTrail.config.track_associations = false
PaperTrail::Rails::Engine.eager_load!

module PaperTrail
  class Version < ActiveRecord::Base
    def user
      User.find(whodunnit.to_i)
    end
  end
end

# frozen_string_literal: true

module StubbableUser
  module ClassMethods
    attr_writer :stub

    def clear_stub!
      Functions.delete_all_keys!
      @stub = nil
      @system_user = nil
    end

    def authenticate!(css_id: nil, roles: nil, user: nil)
      Functions.grant!("System Admin", users: ["DSUSER"]) if roles&.include?("System Admin")

      if user.nil?
        user = User.from_session(
          "user" =>
            { "id" => css_id || "DSUSER",
              "name" => "Lauren Roth",
              "station_id" => "283",
              "email" => "test@example.com",
              "roles" => roles || ["Certify Appeal"] }
        )
      end

      RequestStore.store[:current_user] = user
      self.stub = user
    end

    def current_user
      @stub
    end

    def clear_current_user
      clear_stub!
    end

    def unauthenticate!
      Functions.delete_all_keys!
      RequestStore[:current_user] = nil
      self.stub = nil
    end

    def from_session(session)
      @stub || super(session)
    end
  end

  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end
end

User.prepend(StubbableUser)

def clean_application!
  User.clear_stub!
  Fakes::CAVCDecisionRepository.clean!
  Fakes::BGSService.clean!
  Fakes::VBMSService.clean!
end

def current_user
  User.current_user
end

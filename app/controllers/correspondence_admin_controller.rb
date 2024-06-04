class CorrespondenceAdminController < CorrespondenceController
  before_action :verify_correspondence_intake_access



  def verify_correspondence_admin_access
    current_user.admin? || current_user.inbound_ops_team_supervisor? || bva?
  end


  private

  def bva?
    Bva.singleton.user_has_access?(current_user) ||
      BvaIntake.singleton.user_has_access?(current_user) ||
      BvaDispatch.singleton.user_has_access?(current_user)
  end





end

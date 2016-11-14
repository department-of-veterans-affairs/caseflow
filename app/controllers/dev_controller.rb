class DevController < ApplicationController

	def set_user
		session["user"] = User.authentication_service.get_user_session(params[:id])
		redirect_to "/dev/users"
	end

end
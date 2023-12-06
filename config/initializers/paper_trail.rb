module PaperTrail
  class Version < ActiveRecord::Base
    def user
      User.find(whodunnit.to_i)
    end
  end
end

# make sure whodunnit is set in console
Rails.application.configure do
  console do
    PaperTrail.request.whodunnit = ->() {
      @paper_trail_whodunnit ||= (
        until RequestStore[:current_user].present? do
          puts "=" * 80
          print "Enter RequestStore[:current_user] CSS id (used by PaperTrail to record who changed records)? "
          css_id = gets.chomp
          RequestStore[:current_user] = User.find_by_css_id css_id
        end
        puts "PaperTrail whodunnit = #{RequestStore[:current_user].css_id}"
        puts "=" * 80
        RequestStore[:current_user].id
      )
    }
  end
end

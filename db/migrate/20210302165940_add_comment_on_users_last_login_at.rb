class AddCommentOnUsersLastLoginAt < Caseflow::Migration
  def up
    change_table_comment :users, "Authenticated Caseflow users"
    change_column_comment :users, :last_login_at, "The last time the user-agent (browser) provided session credentials; see User.from_session for precision"
  end
  def down
    change_table_comment :users, ""
    change_column_comment :users, :last_login_at, ""
  end
end

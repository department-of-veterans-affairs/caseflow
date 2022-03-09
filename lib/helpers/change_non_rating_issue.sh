rails c << DONETOKEN
x = WarRoom::ChangeNonRatingIssue.new
x.run("$1")
DONETOKEN
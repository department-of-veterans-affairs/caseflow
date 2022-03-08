bin/rails c << DONETOKEN
RequestStore[:current_user] = User.system_user

dvc = DuplicateVeteranChecker.new

dvc.run_remediation("$1")

DONETOKEN
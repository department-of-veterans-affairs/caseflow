bin/rails c << DONETOKEN
RequestStore[:current_user] = User.system_user

dvc = DuplicateVeteranChecker.new

dvc.check_by_duplicate_veteran_file_number("$1")

DONETOKEN
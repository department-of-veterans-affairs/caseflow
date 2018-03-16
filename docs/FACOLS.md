Running Caseflow connected to FACOLS is [well documented in the README](https://github.com/18F/uswds-rails-gem#usage). This document is to explain the following:
1) How to add new cases to FACOLS
1) How to add new tables to FACOLS
   1) How sanitizaiton of data works

# Adding new cases to FACOLS
We check FACOLS data directly into GitHub since the data has been scrubbed of any PII. The test data comes from the RDS instance named: `dsva-appeals-vacols-uat-datasource-2017-12-13-11-20`. This is a copy of UAT from December 2017 which means that it contains PII. We pull a subset of the data from this RDS instance, sanitize it, and dump it to CSV files that we check into `local/vacols`. The master list of cases in FACOLS is maintained in `local/vacols/cases.csv`. Here is an example exerpt from the file:

|vacols_id|vbms_id|bgs_id|used_in_app|comments|
|---|---|---|---|---|
|3575931|static_documents||reader queue|Case assigned to attorney|
|3619838|no_categories||reader queue|Case assigned to attorney|
|3625593|random_documents||reader queue|Case assigned to attorney|

The `vacols_id` column represents the `bfkey` from the `brieff` table. This is just an identifier and so is not PII. The `vbms_id` currently is used to specify which documents we want to associate with this case. The choices are `static_documents`, `no_categories`, `random_documents`, `redacted_documents`. In the future this field will be used to coordinate how this case associates with VBMS data. `bgs_id` is currently not used, but will have an analogus purpose to `vbms_id`. `used_in_app` is a list of which apps rely on this case. If you no longer need a case, remove the app from this list. If not apps are using it, it's safe to remove. Conversly if you start using a case, add your app's name to this list so no one else removes it from the list. `comments` are anything you'd like to add to give this case context.

Adding a case is as simple as adding a row to this CSV. To find a relevant `vacols_id` to use, you can run the rails console in the ssh_forwarding environment. This will enable you connect to the datasource RDS instance to peruse the available data. Instructions of connecting can be found [here](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/how-to-setup-ssh-port-forwarding.md). Note the ssh command to run to connect to the datasource RDS instance is: `ssh -L 1526:dsva-appeals-vacols-uat-datasource-2017-12-13-11-20.cdqbofmbcmtd.us-gov-west-1.rds.amazonaws.com:1526 <whatever your UAT jumpbox config is>`. Once connected, you can run any queries you want to find the useful cases, then get their `bfkey`s from the `brieff` table and copy them into the `cases.csv` file.

To actually retrieve all the data for the cases you added you'll need to run our new rake task:
```
RAILS_ENV=ssh_forwarding rake local:vacols:dump_data
```

This will dump data into the relevant CSV files in `local/vacols` so they can be imported later into FACOLS. Once this finishes running, you might (but are unlikely to) see red-text explaining that there may be PII in the data you pulled. If this is the case, we may need to whitelist or fake out another field. Coordinate with Mark and Chris to make this happen.

Once the data has been dumped and you receive no warnings about PII, check in the resulting changes to the dumped-data CSVs, and run the FACOLS seed job:
```
RAILS_ENV=local rake local:vacols:seed
```

This will seed FACOLS with the new data. After this you should be good to go! Note all PII will be sanitized, and staff ids will be scrambled, but you can backtrack any necessary information from the bfkey which stays the same.

# Adding new tables to FACOLS

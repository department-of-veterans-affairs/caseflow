Running Caseflow connected to FACOLS is [well documented in the README](https://github.com/department-of-veterans-affairs/caseflow/blob/master/README.md). This document explains more advanced FACOLS usage. Specifically:
1) How to add new cases to FACOLS
1) How to add new tables to FACOLS
   1) How sanitizaiton of data works

# Adding new cases to FACOLS
We check FACOLS data directly into GitHub since the data has been scrubbed of any PII. The test data comes from the RDS instance named: `dsva-appeals-vacols-uat-datasource-2017-12-13-11-20`. This is a copy of UAT from December 2017 which means that it contains PII. We pull a subset of the data from this RDS instance, sanitize it, and dump it to CSV files that we check into `local/vacols`. The master list of cases in FACOLS is maintained in `local/vacols/cases.csv`. Here is an example excerpt from the file:

|vacols_id|vbms_id|bgs_id|used_in_app|comments|
|---|---|---|---|---|
|3575931|static_documents||reader queue|Case assigned to attorney|
|3619838|no_categories||reader queue|Case assigned to attorney|
|3625593|random_documents||reader queue|Case assigned to attorney|

The `vacols_id` column represents the `bfkey` from the `brieff` table. This is just a DB primary key and so is not considered PII. The `vbms_id` currently is used to specify which documents we want to associate with this case. The choices are `static_documents`, `no_categories`, `random_documents`, `redacted_documents`. In the future this field will be used to coordinate how this case associates with fake VBMS data. `bgs_id` is currently not used, but will have an analogous purpose to `vbms_id`. `used_in_app` is a list of which apps rely on this case. If you no longer need a case, remove the app from this list. If no apps are using it, it's safe to remove this row from the CSV. Conversely if you start using a case, add your app's name to this list so no one else removes it from the list. `comments` are anything you'd like to add to give this case context.

Adding a case is as simple as adding a row to this CSV. To find a relevant `vacols_id` to use, you can run the rails console in the ssh_forwarding environment. This will enable you connect to the datasource RDS instance to peruse the available data. Instructions of connecting can be found [here](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/how-to-setup-ssh-port-forwarding.md). Note the ssh command to run to connect to the datasource RDS instance is: `ssh -L 1526:dsva-appeals-vacols-uat-datasource-2017-12-13-11-20.cdqbofmbcmtd.us-gov-west-1.rds.amazonaws.com:1526 <whatever your UAT jumpbox config is>`. Once connected, you can run any queries you want to find useful cases, then get their `bfkey`s from the `brieff` table and copy them into the `cases.csv` file.

To actually retrieve all the data for the cases you added you'll need to run our new rake task:
```
RAILS_ENV=ssh_forwarding rake local:vacols:dump_data
```

This will dump data into the relevant CSV files in `local/vacols` so they can be imported later into FACOLS. Once this finishes running, you might (but are unlikely to) see red-text explaining that there may be PII in the data you pulled. If this is the case, we may need to white-list or fake out another field. Coordinate with Mark and Chris to make this happen.

Once the data has been dumped and you receive no warnings about PII, check in the resulting changes to the dumped-data CSVs, and run the FACOLS seed job:
```
RAILS_ENV=local rake local:vacols:seed
```

This will seed FACOLS with the new data. Note when seeding data, all date-time fields are date shifted as if today was November, 1, 2017. In this way we can keep even old data current. After this you should be good to go! Note all PII will be sanitized, and staff ids will be scrambled, but you can backtrack any necessary information from the bfkey which stays the same.

# Adding new tables to FACOLS
Adding a new table to FACOLS is significantly harder than just adding a new case. When adding a new table you must add code to sanitize any potential PII. But before sanitization we need the boilerplate. Every table we add must have a wrapper class just like `VACOLS::Case` that defines the table for active record. Once that's established there are two different procedures to add two different types of tables.

1) You could add a table that is related to the `brieff` table. For example, the `hearsched` table belongs to the brieff table. For these tables, we pull in rows that relate to the cases specified in the `cases.csv` file. To add the table, you'll need to add two things to the `local:vacols:dump_data` rake task defined in `vacols.rake`. First, although technically optional, to reduce the number of queries you can add the table to the `VACOLS::Case.includes` statement. Then you'll need to add a line similar to `write_csv(VACOLS::CaseHearing, cases.map(&:case_hearings), sanitizer)`. This writes the data from each `case_hearings` row that corresponds to a given `case`.
2) You could add a table that is not related to the `brieff` table. For example the `staff` table has all the BVA staff members in it. For these kinds of tables, we must select which rows to bring in. What you choose depends on the use case. Some tables are completely dumped, while in others we only dump certain rows. Look at how we dump the `tbsched` table for reference:
   ```
   write_csv(
      VACOLS::TravelBoardSchedule,
      VACOLS::TravelBoardSchedule.where("tbyear > 2016"),
      sanitizer
   )
   ```
   
Once a table is pulled in, we need to sanitize it. As you can see from the previous step, the `write_csv` function takes in a `sanitizer` object. This sanitizer is defined in `sanitizers.rb`. In `write_csv` we call a `sanitize` method which uses meta-programming to call two methods specific to the class we're sanitizing. The first is `white_list_#{lower_case_class_name}`. This method must return a string array of a set of fields to white list. All other fields are immediately nilled out. This is to ensure we don't actually write a field we do not intend to. The second is `sanitize_#{lower_case_class_name}`. This allows us to fake out fields that were or were not white listed. If either of these methods are not defined, then sanitization will fail.

Similar to the first section in this doc, to get the data and seed it into FACOLS you'll need to run

```
RAILS_ENV=ssh_forwarding rake local:vacols:dump_data
RAILS_ENV=local rake local:vacols:seed
```

and check the resulting CSV updates into git.

When sanitization is run, we examine all white-listed fields for PII, including emails, phone numbers, sentences, and vet ids. If any field matches any of these RegExs then we print it in red at the end of the dump data job. This can alert you to a possible leak. To respond, you should either, stop white-listing the field if it is actually PII, or add the field to a special white-list for fields that detect PII but don't actually contain it. This white-list is in the `ignore_pii_in_fields` method. Even with these safeguards, when adding a new table, please coordinate with Mark and Chris to make sure we don't accidentally leak PII.

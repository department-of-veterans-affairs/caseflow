---
title: VACOLS
tags: "vacols"
weight: 30
---

# VACOLS

This page documents the VACOLS DB and its schema.
* VACOLS is the source of truth for Legacy Appeals.
* [VACOLS GitHub repo](https://github.com/department-of-veterans-affairs/VACOLS/tree/master/docs)
* [DBDiagram of VACOLS table relationships](https://dbdiagram.io/d/5f8225973a78976d7b77234f)
* [VACOLS Data Dictionary spreadsheet](https://docs.google.com/spreadsheets/d/1I8vb7PWeDSJBQhwUFAkvywlwNXJW0KnzQQtb_rxz7j4/edit?usp=sharing) copied from VACOLS.Database.tables.pdf (Last Updated: July 12, 2016). Ask for permission to edit via Google.
* [Docs in the VACOLS repo](https://github.com/department-of-veterans-affairs/VACOLS/tree/master/docs)
  - [VACOLS Reference docs](https://github.com/department-of-veterans-affairs/VACOLS/tree/master/docs/VACOLS%20Reference%20Docs) - VACOLS_Table_Joins.xls
  - [Feb 2017 VACOLS doc in appeals-data repo](https://github.com/department-of-veterans-affairs/appeals-data/blob/master/vacols.pdf) - explanations of example queries
* [FACOLS - "Fake VACOLS" used for local testing](https://github.com/department-of-veterans-affairs/caseflow/wiki/FACOLS)

## Caseflow's Rails Source Code for VACOLS DB
[Caseflow's VACOLS Rails models](https://github.com/department-of-veterans-affairs/caseflow/tree/master/app/models/vacols)
* [appeal_repository.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/appeal_repository.rb) to query and update VACOLS
* [case.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/vacols/case.rb) has mappings of VACOLS values to more intuitive values
* [legacy_appeal.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/legacy_appeal.rb) - model that queries VACOLS for Legacy appeal info
* [vacols_helper.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/helpers/vacols_helper.rb) - utility methods to handle VACOLS quirks
* [associated_vacols_model.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/concerns/associated_vacols_model.rb)
  - `vacols_attr_accessors` will lazy load the underlying data from the VACOLS DB upon first call.
    For example, `appeal = LegacyAppeal.find(id)` will *not* make any calls to load the data from VACOLS,
    but soon as we call `appeal.veteran_first_name`, it will trigger the VACOLS DB lookup and fill in
    all instance variables for the appeal. Further requests will pull the values from memory and not
    do subsequent VACOLS DB lookups
  - `AppealRepository.load_vacols_data` calls [`set_vacols_values`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/appeal_repository.rb#L177) to load appeal (aka "case") information from VACOLS.
* [Location codes](https://github.com/department-of-veterans-affairs/appeals-support/wiki/VACOLS-Location-Codes) - in the [code](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/legacy_appeal.rb#L149)

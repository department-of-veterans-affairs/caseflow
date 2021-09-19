---
title: Data Models
bookToC: false
menu:
  navmenu:
    identifier: data-model
    collapsible: true
weight: 3
---

# Caseflow Data Models

This section provides information about Caseflow's data model, data dictionary, and resources to help understand Caseflow's database contents ([terminology](https://dataedo.com/blog/data-model-data-dictionary-database-schema-erd) and [example data-dictionaries](https://www.usgs.gov/products/data-and-tools/data-management/data-dictionaries)).
The main audience are Caseflow engineers, BVA's Reporting Team, and onboarders.

Also check out [Caseflow Database Schema Documentation](schema_diagrams).

## Contents
{{< pages_list >}}

### Instructions for adding documentation

* Document any non-obvious semantics or logic that would be useful when interpreting database tables and constituent data.
   * Reference other relevant wiki pages to provide context/background.
   * Link to relevant code (in case it changes in the future).
* To create tables diagram, go to http://dbdiagram.io/, click "Import", and paste table definition excerpts from [`schema.rb`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/db/schema.rb); then add cross-table links using the mouse and move the boxes around to your liking. Click "Save" and copy the URL to this page.
   * Note: you can only import once; try it a couple of times to get a hang of it before spending too much time.
   * Table columns with `***` in the name are used to designate categories of columns. In the Certifications diagram, you will see a column titled `_initial ***` in the Form8s table. The Form8s table has twelve columns beginning with "_initial": `_initial_appellant_name`, `_initial_appellant_relationship`, etc. To keep the diagram and tables more tidy we grouped these categories together.
   * Pro-tip: Open another browser tab, paste the new excerpt, then copy-and-paste the resulting Table definition into the original tab.
   * To insert a screenshot of the diagram, paste the image into a comment on [ticket #15510](https://github.com/department-of-veterans-affairs/caseflow/issues/15510), which will upload the image to GitHub and provide a URL for the image, which can then be linked from this page.

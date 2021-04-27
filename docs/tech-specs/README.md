# Technical Specifications

This folder contains tech specs for the Caseflow team.

### Some common guidelines for when to write a tech spec are:

- The implementation of a solution has downstream effects for future work
- There are intricate details that you need to get feedback on before implementing a PR
- There are multiple ways of implementation each with their own pros/cons
- This is a change to an integration or shared resource that may be have implications for other Caseflow teams
- You want feedback from other engineers on approach

### The goals of the tech spec process are:
* Document and share technical knowledge with current and future team mates
* Log reasoning for technical decisions
* Make better technical decisions by rigorously discussing with more engineers

## In order to write a tech spec and get it reviewed do the following:
1. Clone this repo
2. Start drafting a tech spec by opening a PR creating a file titled YYYY-MM-DD-(tech-spec-name).md in this folder with your tech spec. You can use the [tech spec template here](https://github.com/department-of-veterans-affairs/caseflow/blob/master/.github/ISSUE_TEMPLATE/tech-spec.md)
3. Post in #appeals-engineering and request for others to review the tech spec
4. Schedule time on the VA Appeals calendar with your scrum team or the whole Caseflow engineering team as appropriate to discuss the tech spec
5. Once comments are addressed, the tech spec is finalized and your PR is approved, merge your commit to master so that the tech spec is preserved for future team mates
6. Link your tech spec in future PRs that implement the changes
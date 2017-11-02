As we roll out Reader to 700 users, we've noticed some pain points in the way engineering and support communicate. This doc seeks to outline some ways in which we can more effectively collaborate.

# Motivations
1) As our products scale linearly, the amount of feedback we receive increases linearly. While pinging tech leads with 1-2 issues a week is manageable, pinging tech leads with 1-2 issues per day is not. This leads to a lot of context switching, and inevitably, difficulty prioritizing.
1) As we introduce new products it will be harder for support to retain context on all of them.
1) Questions that require product knowledge have to be answered by product owners or engineers. Users who have these questions often don't get answers.

# Proposals
Below are three proposals for three different types of support tickets.
## FAQs - (User error and Common Known Bugs)
When support fields a one-off question that they don't know the answer to:

1) Check user help FAQs
1) Check centralized support-FAQ
1) Ping PM
1) If PM is unavailable, ping tech lead
1) Record this question and answer in centralized support-FAQ

## Creating or linking to engineering tickets - (Low Priority)
It's always difficult to disambiguate low priority from high priority. So we set the following standard: if only one user has sent in feedback on a specific issue within a given day then we treat it as low priority. Support should either find an existing ticket in the product repo (caseflow, caseflow-efolder, etc.) or they should make a new ticket in one of those repos. These tickets should be marked with the support label. The ticket in the product repo should link to each instance in the support repo so that we have context on who reported it and how often it was reported. If support sees more than 5 support issues for a given product ticket they should ping the tech lead about that ticket.

## Pinging tech leads - (High Priority)
If more than one user reports a bug within 24 hours, then we treat the issue as high priority. The tech lead should be notified immediately so an investigation can start.

# Coordination
## Training
Support should receive regular training from product teams so that they understand products in depth. This will help them triage issues.

## Questions to ask users
Product teams should provide support with a list of questions to ask users. This may vary between teams but will consist of something like:
- What is the URL of the page?
- What is the file number?
- If the application is slow, are other VA services (like VBMS) slow?

## Proposed Updates to Existing Sub-Tasks

- [ ] Send Reporter Acknowledgement. Ask above follow-up questions
- [ ] Assess Issue
   - How many users have sent in this or a related issue?
   - Check user help FAQs
   - Check centralized support-FAQ
- [ ] Create new engineering ticket, or link to existing engineering ticket
- [ ] If more than one user has reported this within 24 hours, ping PM and tech lead
- [ ] Received Team Acknowledgement
- [ ] Update Reporter
- [ ] Resolve Issue
- [ ] Received Completion Notice
- [ ] Update Reporter - Issue Complete
- [ ] Close NSD ticket, if applicable
- [ ] Confirm/Update Knowledge Base

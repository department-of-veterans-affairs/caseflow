# Readiness Checklists

This is being piloted by the Whiskey team.

## Ready For Dev
1. Acceptance criteria includes handling for the following (or explicitly stating that they are out of scope or not applicable):
  1. Accessibility
    1. Keyboard operability
    1. Screen-reader usability
  1. Error handling
    1. Invalid / unexpected user input
    1. Server failure
  1. Data persisting to the backend
    1. What actions cause data to be saved?
    1. Is there a loading indicator?
    1. Is there a "save successful" indicator?
  1. Pixel or percentage measurements for layout
  1. Specify all colors used (preferably in terms of semantic variables like `$tag-backgrond-color`)
1. Ensure that all necessary SVGs are linked from the ticket and render correctly in the GitHub browser
1. Mockups and specs
  1. If the mockups and specs are inconsistent with each other, or are out of date, please note this explicitly.
1. Where applicable (for more complicated tickets), please include a brief rationale for this solution to the problem.
1. If a specific component from the styleguide is supposed to be used, please name that component.

## Ready For PR
1. The PR improves the app in some way
1. Tests are passing on Travis
1. New tests are added for new functionality
1. Best practices
  1. No computed state is being stored in Redux
  1. Lodash is being used effectively
1. Feedback from previous PRs about style and best practices is applied in this PR as well
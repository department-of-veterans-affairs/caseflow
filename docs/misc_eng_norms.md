We want to foster a strong spirit of collaboration on the Caseflow team. Below, we’ve listed out some miscellaneous norms that help keep engineering humming.


## Technical improvements

Developers are encouraged to identify technical debt items and create GitHub issues for them. Each sprint should contain some technical improvement items. If you see something, say something! When you create a GitHub issue, you should add information into it such that another developer could take on the task. Reference https://github.com/department-of-veterans-affairs/caseflow/issues/1731 for an example. 
 
## Code Comments
 
When you’re looking over the codebase, try to ask yourself “Would someone who’s never seen this before be confused about the purpose of this code snippet?” If the answer is yes, refactoring is the preferred option. If that’s not possible at the moment, consider adding a comment.
 
TODOs are used to describe improvements that could or should be made to the codebase, 'e.g. TODO: (alex) refactor this out into its own module.'
 
Each TODO should have a name alongside it so the commenter can be pinged later for additional context and discussion. 
 
Explanatory comments are used to give added context on some item. They’re especially useful to add some business context to code that’s heavy with domain-specific concepts, as well as to add example of how more abstract methods can be used.
 
Feel empowered to delete other people’s comments if they’ve become stale or redundant. 

## Commit Messages
Follow [these guidelines](https://chris.beams.io/posts/git-commit/) for writing a good commit message. When merging with the "squash and merge" button, rewrite the text that GitHub automatically suggests, which is just a concatenation of every commit message.

* [Bad example](https://github.com/department-of-veterans-affairs/caseflow/commit/d5ab5a00cf4b0a26da3b0e531865610543da4b9d)
* [Good example](https://github.com/department-of-veterans-affairs/caseflow/commit/eae5435ee9cf318377fcf05e654595731bdec7d9)

## Tickets
When you are actively working on a ticket, add the [In Progress](https://github.com/department-of-veterans-affairs/caseflow/labels/In%20Progress) label. This will make it show up under your name in the [standup app](https://cold-stream-43683.herokuapp.com/sprint/standup?team=CASEFLOW). If you are not going to work on a ticket on a given day, it should not have the "In Progress" label. This helps everyone keep track of what's actually being worked on, instead of diluting the value of GitHub issues as a tool for project management. It also means that someone else on the team could potentially pick up where you left off, if they free up and you're still working on other things. And finally, it avoids falsely communicating to teammates that we're making progress on issues that we're not.

Each engineer should work on no more than three issues at a time. This allows us to have higher throughput by focusing our work. It's better to make a lot of progress on one task than a little bit of progress on five.

Each ticket should be small enough that it can be completed in no more than 2-3 business days. If a ticket takes 4 or more days, then either there are blockers that need to be addressed, or the ticket should be split up into smaller parts. 

As a corollary, each PR should be as small as possible. It should not contain anything extraneous other than what the ticket's acceptance criteria require. Ideally, PRs will be `200` lines or fewer. It is ok to send multiple PRs for a single ticket if that makes it easier to implement and review.

## PR Descriptions

Add "Connects #{github issue number}" to associate your PR with the GitHub issue.
 
Each PR should contain enough information to allow someone to effectively review it. For example, if you're submitting a fix for an obscure bug that causes a blank screen in some edge case, explain the edge case and how your fix prevents the bug. You should aim not to just prove to your reviewer/s that your change works, but to understand and explain **why** it works to a reasonable degree of depth.
 
If your changes are visible in the UI, add one or more screenshots. On OSX, Command + Control + Shift + 4 brings up crosshairs. Select an area of the screen to screenshot, and it will be saved into the clipboard, so you can paste the screenshot directly into the GitHub PR body.
 
Where appropriate, GIFs are also great. Check out [Licecap](http://www.cockos.com/licecap/), a simple program for recording GIFs from your display.
 
Almost every PR should have a “Testing:” section, where you describe how you validated your change. For complex changes, the testing section may be quite extensive, but for simple changes like styling or content, it might be no more than “Verified change in UI.”

## Code Reviews
 
The best way to ensure shared context and correct software is through a culture of deep code reviews. Expect your reviewer to poke holes in your reasoning, point out improvements, ask you to test more thoroughly, add more unit tests, etc. This is done out of love and reverence for our project.
 
As the reviewer, be mindful of scope creep. Sometimes, it takes more than one PR to put the code in a good state. As the dev, if you feel you’re being asked to significantly expand the scope of the original change, it’s perfectly fine to say “I agree with your comment, but I think that change is out of scope and should be addressed in a future PR. 
 
If you and your reviewer disagree on the technical direction, try your best to see the other point of view. You’re encouraged to seek third or fourth or ++ opinions if desired.
 
## Changes to shared development infrastructure
 
We want to preserve a culture of continuous improvement, where developers are empowered to make ambitious changes and take initiative. However, we also recognize that it can be disruptive to update from master and have your environment break.
 
Changes to the developer environment/build system are often very difficult to test, and carry with them a high risk of blocking other team members. Proactive communication minimizes the cost of these changes. If you're making a change to development infrastructure, please alert the entire engineering team like so: "@here, I'm about to merge in #{description of change}. I've tested it by X, but if you see anything odd or broken, please ping me." If you have deep context on the change, try to make yourself available post-merge to unstick people, as a few minutes of your debugging time may save an hour of someone else's. 
 
Other potentially helpful strategies to reduce the pain of dev environment changes:
- have one or more other devs test your changes pre-merge
- ask the team to refresh from master at their earliest convenience, so everyone can debug at the same time if necessary
 
When in doubt, overcommunicate.
 
## Pair Programming
 
Pair programming is the one of the quickest ways to expand your knowledge of the codebase. When you learn of an interesting ticket during standup, ask that engineer if you can pair with them on it. Similarly, engineers working on a particularly challenging ticket should ask for someone to pair with them. A second set of eyes during development can improve the quality of the code and reduce bugs. 

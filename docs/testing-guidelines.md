# Testing Guidelines

This doc describes how we write automated tests Caseflow. Our current codebase does not entirely reflect this, but the Whiskey team is piloting it with new code going forward.

As much as possible, business logic should exist in pure functions, which is a function whose outputs are only reflective of its inputs, and which does not cause side effects. These functions are easy to unit test.

On the frontend, Redux reducers should have unit tests. Components can also have unit tests via Enzyme. 

The backend should be tested with both unit tests and request-level tests.

The backend and frontend are tested together with Capybara tests. Because Capybara is slow and it's hard to write reliable tests, it should be used as more of a smoke test than an exhaustive proof of correctness. Try one or two permutations in Capybara, and verify all the edge cases in unit tests.

Before deployment, Artem's full stack integration tests will also run. 

## Capybara
* [Never `sleep`](https://nulogy.com/who-we-are/company-blog/articles/sleep-is-for-the-weak/).
* When a new test is added in a PR, wrap it in the `ensure_stable` helper:
    ```rb
    # Wrap this around your test to run it many times and ensure that it passes consistently.
    # Note: do not merge to master like this, or the tests will be slow! Ha.
    def ensure_stable
        10.times do
            yield
        end
    end

    ensure_stable do
        scenario "my new test" do
        end
    end
    ```
    This will run your test many times, and you can ensure that it passes consistently. This way, we don't accidentally merge flakey tests to `master` just because we see them passing once. Just be sure not to merge to `master` with `ensure_stable` still applied.

## JS Components
Testing a pure function is easy, because you can just assert on the return value. By default, React components are pure functions, which take in `props` and return HTML. For instance, this is a clean test:

```js
it('renders e-Folder Express logo', () => {
const wrapper = shallow(<Logo app="efolder"/>);

expect(wrapper.find('.cf-logo-image-efolder')).to.have.length(1);
});
```

However, when we introduce mocks, spies, and stubs, the test can quickly become more complicated and less relevant to what the user experiences at once:

```js
it(`calls onPageChange with 1 and ${PdfJsStub.numPages}`, asyncTest(async() => {
    wrapper.instance().setUpPdf('test.pdf');
    await pause();

    expect(
        onPageChange.calledWith(1, PdfJsStub.numPages, sinon.match.number)
    ).to.be.true;
}));
```

The user does not know or care that there's a function called `onPageChange` that will be called. And when we eventually change how the component signals that the page needs to change, this test will break, even though there's nothing different from the user's perspective. And finally, an incorrect method calling pattern is way more difficult to debug via Sinon than an incorrect return value.

If we can't validate this fuctionality by asserting on the return value of `render()`, then we should be using a Capybara test.

Likewise, tests that involve browser navigation should be done in an actual browser, via Capybara.

The only mocking that's acceptable in a JS test is at the `XMLHttpRequest` level.

## See Also
* [Testing JavaScript](https://medium.com/@nickheiner/testing-javascript-8c8efe8434e)

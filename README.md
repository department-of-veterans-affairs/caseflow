---
nav_order: 0
---

# README

[GitHub Pages](https://pages.github.com/) for [Caseflow](https://github.com/department-of-veterans-affairs/caseflow)

Caseflow's GitHub Pages can be viewed at http://department-of-veterans-affairs.github.io/caseflow/

## Purpose of the `gh-pages` and `main-gh-pages` branches

The ([`gh-pages` branch](https://github.com/department-of-veterans-affairs/caseflow/tree/gh-pages)) is used by GitHub Pages. The branch is not intended to be merged in the main branch. Note that it has a completely separate commit history from the main branch. For more info, see ...

This branch has files for documentation. Some are automatically generated (e.g., [Caseflow DB schema](schema/index.html) by a GitHub Action); others are manually created (e.g., [Bat Team Remedies](batteam/index.html)).

The `gh-pages` branch is updated by a `build-gh-pages` GitHub Action that uses files from the `main-gh-pages` branch to generate `html` and asset files, which are pushed to the `gh-pages` branch. You should not modify the `gh-pages` branch directly. Any commit to the `main-gh-pages` branch will trigger the GitHub Action, which can be seen [here](https://github.com/department-of-veterans-affairs/caseflow/actions/workflows/build-gh-pages.yml). See [Committing changes](committing-changes) for how to make changes.

## Cloning / Checkout

Even though `main-gh-pages` is another branch in the Caseflow repo, it is highly encouraged to check out the `main-gh-pages` branch in a separate because it has no common files with Caseflow's `master` branch.

To checkout to a `caseflow-gh-pages` directory as a sibling of your `caseflow` directory:
```
cd YOUR_PATH_TO/caseflow
cd ..
git clone -b gh-pages https://github.com/department-of-veterans-affairs/caseflow.git caseflow-gh-pages
```

## Making changes

For small changes, most pages can be modified by clicking on the `Edit this page` link at the bottom of the page, modifying the `md` file, and committing the change.

## Committing changes

Treat the `main-gh-pages` branch like Caseflow's `master` branch. A difference is that anyone can commit to `main-gh-pages` without a peer-review, just like the Caseflow wiki page. However for significant changes, it is encouraged to create a development branch and do a squash-merge when you are satisfied with the changes, just like what is done in Caseflow's `master` branch.

## Previewing changes

To preview changes locally, run the website generators locally as follows:
```
...
bundle exec jekyll serve
```

## FAQ

### Why not use the GitHub Wiki?

GitHub Wiki has the following limitations:
- no table of content generation
- cannot reflect organization of wiki pages as folders
- ...

Benefits of GitHub Pages
- more control over web page organization
- ...

### Why not use the basic GitHub Pages?

https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/about-github-pages-and-jekyll




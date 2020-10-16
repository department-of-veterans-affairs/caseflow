# Overview

This refactor will be limited to the Reader codebase within the greater Caseflow application and will not introduce any new logic nor will it change any existing logic. The purpose of this refactor will be to fix the underlying bug that is causing the reader documents table to lose filters between screen changes. We also hope to add some additional changes that will improve the overall codebase, but be isolated to the Reader codebase at first.

This refactor would also include a feature flag to hide the changes behind so that we can preserve the existing codebase while we are testing the refactored changes.

## Changes

Below are the changes that we are hoping to make during the refactor that we believe will bring the best value:

- Move the logic that currently exists in individual components into a central Redux store (curently scoped to the Reader code, but that could be expanded upon later)
- Introduce a new folder structure that can be used for the Reader code at first, but that could be expanded to be used by the entire application in the future (NOTE: this would preserve the existing structure, but add some additional folders that could be migrated to at some point). The proposed structure would be as follows:

**NOTE:** `index.js` files will be used to export all components/functions from a given folder allowing us to also add tree shaking as a performance improvement
```
...
app
└── 2.0
    ├── layouts // Components to structure screens in a standardized way
    |   ├── BaseLayout.jsx // Includes app banner, footer and site-wide navigation
    |   ├── TableLayout.jsx // A layout that primarily centers around a table
    │   └── index.js
    ├── routes // Holds the routing information for different groups of screens
    |   ├── reader.jsx
    │   └── index.js
    ├── screens // Contains top-level screens that are redux-connected and pass state down through props
    │   ├── reader
    |   │   ├── DocumentsTable.jsx
    |   │   └── Document.jsx
    │   └── index.js
    ├── store
    │   ├── actions
    │   │   ├── reader
    │   │   └── index.js
    │   ├── dispatchers
    │   │   ├── reader
    │   │   └── index.js
    │   └── reducers
    │       ├── reader
    │       └── index.js
    └── components // Contains independent components used for constructing parts of individual screens
        ├── reader
        └── index.js
...
```
- Add webpack aliasing to make it easier to move components around and know exactly where they are located
- Upgrade some of the outdated packages that belong to Reader including but not limited to the PDFjs package which is currently a full major version behind
- Lazy load components to reduce the overall size of the webpack bundle and speed up page loads

## Goals

By implementing the above changes, we believe that we will be able to achieve the following in addition to resolving the underlying Reader bug

- Improve readability of the codebase
- Improve the performance of the Reader application
- Reduce the complexity of the codebase to increase the speed at which we are able to determine these types of issues
- Mitigate future bugs by reducing the number of places that a bug could occur

## Capacity

We believe that the above refactor would require the following engineering capacity and no capacity from any other teams:

**Engineers:** 1-2
**Story Points:** 8-13 (1-2 Sprint)
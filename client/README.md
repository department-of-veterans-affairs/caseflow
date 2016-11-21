# Caseflow Frontend

## About

Caseflow's frontend is built using React & Webpack. React is the framework we use to organize our frontend code into reusable, extensible components. Rails still handles all web routing, and determines when react components should be rendered.

## Asset Compilation Process

![Screenshot of Asset Compile](./asset-compile-diagram.png "Asset Compile Diagram")

The frontend code is compiled using [Webpack](https://webpack.github.io/) & [Babel](https://babeljs.io/). The webpack takes `client/app/index.js` as its input file, and after compilation outputs the resulting javascript file to `app/assets/webpack/webpack-bundle.js`. During compilation, the frontend code goes through two key transformations. First, the initial ES6 JS frontend code is transformed into ES5 (supported in all browsers today). Second, the HTML-like JSX code is transformed into pure JS. By performing these transformations, the resulting `webpack-bundle.js` is pure ES5 JS that is ready for use by Rail's asset pipeline.

## Adding a New JS Library

Caseflow's frontend uses npm (Node Package Manager) to manage its JS dependencies. Similar to Rail's Gemfile, the frontend manages its dependencies via a `package.json` file located in `/client`. You can search for JS libraries on [NPM's website](https://www.npmjs.com/). To add a new dependency:

> $ npm install new-library --save

This will add information about the library to the `package.json`. Then to install the new dependency:

> $ npm install

## Styling

CSS styling continues to be handled by Rails and the asset pipeline. To add new styling:

- Open the relevant file in `app/assets/stylesheets`
- Add new styling as needed
- Reload the page


## Testing

Frontend unit tests are run using [Mocha](https://mochajs.org/). When possible, testing of frontend code should be accomplished through Capybara feature spec tests. That is, container components (e.g. pages) should _not_ be tested via mocha tests. Only true components should be unit tested via mocha. See example component tests in [/test](test).

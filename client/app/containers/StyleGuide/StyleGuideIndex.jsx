import React from 'react';
import StyleGuideModal from './StyleGuideModal';
import StyleGuideTabs from './StyleGuideTabs';
import StyleGuideLoadingButton from './StyleGuideLoadingButton';

export default class StyleGuideIndex extends React.Component {

/* eslint class-methods-use-this: ["error", { "exceptMethods": ["render"] }] */
  render() {

/* eslint-disable max-len */

    return <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt">
      <div className="cf-push-left cf-sg-nav">
          <ul className="usa-sidenav-list">
            <li>
              <a href="/styleguide#">Introduction</a>
            </li>
            <li>
              <a href="#modals">Modals</a>
            </li>
            <li>
              <a href="#tabs">Tabs</a>
            </li>
            <li>
              <a href="#loading_button">Loading Button</a>
            </li>
          </ul>
      </div>
      <div className="cf-push-right cf-sg-content">
      <h1 id="commons">Caseflow Commons</h1>
        <p>
          Caseflow Commons is home to our most up to date style guide, UI Kit, and code for Caseflow products.
          The goal is to maintain consistent styling across Caseflow applications and to keep our interface predictable and familiar to the user.
          This unified system also helps us reuse common code across our apps and increase the efficiency of the design process.
        </p>
        <p>
          <a className="usa-button"
            href="https://github.com/department-of-veterans-affairs/caseflow-commons">
            View on Github
          </a>
          <a className="usa-button usa-button-outline"
          href="https://github.com/department-of-veterans-affairs/appeals-design-research/issues/8">
          Download UI Kit</a>
        </p>
        <div className="cf-help-divider"></div>
        <StyleGuideModal />
        <div className="cf-help-divider"></div>
        <StyleGuideTabs />
        <div className="cf-help-divider"></div>
        <StyleGuideLoadingButton />
    </div>
    </div>;
  }
}

/* eslint-enable max-len */

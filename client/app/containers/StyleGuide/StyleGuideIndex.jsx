import React from 'react';
import StyleGuideModal from './StyleGuideModal';
import StyleGuideTabs from './StyleGuideTabs';
import StyleGuideProgressBar from './StyleGuideProgressBar';
import StyleGuideLoadingButton from './StyleGuideLoadingButton';
import StyleGuideRadioField from './StyleGuideRadioField';
import StyleGuideTables from './StyleGuideTables';
import StyleGuideTextInput from './StyleGuideTextInput';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StickyNav from '../../components/StickyNav';
import NavLink from '../../components/NavLink';

export default class StyleGuideIndex extends React.Component {

/* eslint class-methods-use-this: ["error", { "exceptMethods": ["render"] }] */
  render() {

/* eslint-disable max-len */

    return <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt">
      <StickyNav>
        <NavLink anchor="/styleguide#" name="Introduction"></NavLink>
        <NavLink anchor="#typography" name="Typography"></NavLink>
        <NavLink anchor="#modals" name="Modals"></NavLink>
        <NavLink anchor="#tabs" name="Tabs"></NavLink>
        <NavLink anchor="#loading_buttons" name="Loading Buttons"></NavLink>
        <NavLink anchor="#radios" name="Radio Fields"></NavLink>
        <NavLink anchor="#tables" name="Tables"></NavLink>
        <NavLink anchor="#progress_bar" name="Progress Bar"></NavLink>
        <NavLink anchor="#text_input" name="Text Input"></NavLink>
        <ul className="usa-sidenav-sub_list">
          <NavLink anchor="#inline_form" name="Inline Form"></NavLink>
        </ul>
      </StickyNav>
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
        <StyleGuidePlaceholder
          title="Typography"
          id="typography" />
        <div className="cf-help-divider"></div>
        <StyleGuideModal />
        <div className="cf-help-divider"></div>
        <StyleGuideTabs />
        <div className="cf-help-divider"></div>
        <StyleGuideLoadingButton />
        <div className="cf-help-divider"></div>
        <StyleGuideRadioField />
        <div className="cf-help-divider"></div>
        <StyleGuideTables />
        <div className="cf-help-divider"></div>
        <StyleGuideProgressBar />
        <div className="cf-help-divider"></div>
        <StyleGuideTextInput />
    </div>
    </div>;
  }
}

/* eslint-enable max-len */

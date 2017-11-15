import React from 'react';
import { componentLinks } from './ComponentLinks';
import StyleGuideModal from './StyleGuideModal';
import StyleGuideTabs from './StyleGuideTabs';
import StyleGuideProgressBar from './StyleGuideProgressBar';
import StyleGuideBranding from './StyleGuideBranding';
import StyleGuideButton from './StyleGuideButton';
import StyleGuideRadioField from './StyleGuideRadioField';
import StyleGuideCheckboxes from './StyleGuideCheckboxes';
import StyleGuideTables from './StyleGuideTables';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideMessages from './StyleGuideMessages';
import StickyNav from '../../components/StickyNav';
import NavLink from '../../components/NavLink';
import StyleGuideSearch from './StyleGuideSearch';
import StyleGuideSearchableDropdown from './StyleGuideSearchableDropdown';
import StyleGuideColors from './StyleGuideColors';
import StyleGuideLoaders from './StyleGuideLoaders';
import StyleGuideLayout from './StyleGuideLayout';
import StyleGuideDashboard from './StyleGuideDashboard';
import StyleGuideTypography from './StyleGuideTypography';
import StyleGuideFormFields from './StyleGuideFormFields';
import StyleGuideAccordions from './StyleGuideAccordions';
import StyleGuideAlerts from './StyleGuideAlerts';

export default class StyleGuideIndex extends React.Component {

  render() {
    return <div className="cf-app cf-sg-layout cf-app-segment cf-app-segment--alt">
      <StickyNav>
        {
          componentLinks.map((link, i) => (
            <li key={i}>
              <NavLink {...link} />
            </li>
          ))
        }
      </StickyNav>
      <div className="cf-sg-content">
        <h1 id="commons">Caseflow Commons</h1>
        <p>
            Caseflow Commons is home to our most up to date style guide, UI Kit, and code for Caseflow products.
            The goal is to maintain consistent styling across Caseflow applications and to keep our interface
            predictable and familiar to the user. This unified system also helps us reuse common code across
            our apps and increase the efficiency of the design process.
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
        <StyleGuideBranding />
        <div className="cf-help-divider"></div>
        <StyleGuideTypography />
        <div className="cf-help-divider"></div>
        <StyleGuideColors />
        <div className="cf-help-divider"></div>
        <StyleGuideButton />
        <div className="cf-help-divider"></div>
        <StyleGuideSearch />
        <div className="cf-help-divider"></div>
        <StyleGuideSearchableDropdown />
        <div className="cf-help-divider"></div>
        <StyleGuideCheckboxes />
        <div className="cf-help-divider"></div>
        <StyleGuideRadioField />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Date Input"
          id="date_input" />
        <div className="cf-help-divider"></div>
        <StyleGuideTables />
        <div className="cf-help-divider"></div>
        <StyleGuideTabs />
        <div className="cf-help-divider"></div>
        <StyleGuideAccordions />
        <div className="cf-help-divider"></div>
        <StyleGuideFormFields />
        <div className="cf-help-divider"></div>
        <StyleGuideLoaders />
        <div className="cf-help-divider"></div>
        <StyleGuideAlerts />
        <div className="cf-help-divider"></div>
        <StyleGuideLayout />
        <div className="cf-help-divider"></div>
        <StyleGuideMessages />
        <div className="cf-help-divider"></div>
        <StyleGuideDashboard />
        <div className="cf-help-divider"></div>
        <StyleGuideModal />
        <div className="cf-help-divider"></div>
        <StyleGuideProgressBar />
      </div>
    </div>;
  }

}

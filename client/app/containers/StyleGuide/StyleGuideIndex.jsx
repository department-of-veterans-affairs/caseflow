import React from 'react';
import StyleGuideModal from './StyleGuideModal';
import StyleGuideTabs from './StyleGuideTabs';
import StyleGuideProgressBar from './StyleGuideProgressBar';
import StyleGuideButton from './StyleGuideButton';
import StyleGuideLoadingButton from './StyleGuideLoadingButton';
import StyleGuideRadioField from './StyleGuideRadioField';
import StyleGuideCheckboxes from './StyleGuideCheckboxes';
import StyleGuideTables from './StyleGuideTables';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideMessages from './StyleGuideMessages';
import StickyNav from '../../components/StickyNav';
import NavLink from '../../components/NavLink';
import StyleGuideSearch from './StyleGuideSearch';
import StyleGuideSearchableDropdown from './StyleGuideSearchableDropdown';
import StyleGuideLogos from './StyleGuideLogos';
import StyleGuideColors from './StyleGuideColors';
import StyleGuideLoaders from './StyleGuideLoaders';
import StyleGuideSmallLoader from './StyleGuideSmallLoader';
import StyleGuideLayout from './StyleGuideLayout';
import StyleGuideDashboard from './StyleGuideDashboard';
import StyleGuideTypography from './StyleGuideTypography';
import StyleGuideFormFields from './StyleGuideFormFields';
import StyleGuideAccordions from './StyleGuideAccordions';
import StyleGuideAlerts from './StyleGuideAlerts';

export default function StyleGuideIndex() {

  let componentLinks = [
    {
      anchor: '/styleguide#',
      name: 'Introduction'
    },
    {
      anchor: '#typography',
      name: 'Typography'
    },
    {
      anchor: '#colors',
      name: 'Colors'
    },
    {
      anchor: '#buttons',
      name: 'Buttons'
    },
    {
      anchor: '#search',
      name: 'Search'
    },
    {
      anchor: '#dropdowns',
      name: 'Dropdown Menus'
    },
    {
      anchor: '#checkboxes',
      name: 'Checkboxes'
    },
    {
      anchor: '#radios',
      name: 'Radios'
    },
    {
      anchor: '#date_input',
      name: 'Date Input'
    },
    {
      anchor: '#tables',
      name: 'Tables'
    },
    {
      anchor: '#tabs',
      name: 'Tabs'
    },
    {
      anchor: '#accordions',
      name: 'Accordions'
    },
    {
      anchor: '#form_fields',
      name: 'Form Fields'
    },
    {
      anchor: '#loaders',
      name: 'Loaders'
    },
    {
      anchor: '#small_loader',
      name: 'Small Loader'
    },
    {
      anchor: '#loading_buttons',
      name: 'Loading Buttons'
    },
    {
      anchor: '#alerts',
      name: 'Alerts'
    },
    {
      anchor: '#layout',
      name: 'Layout'
    },
    {
      anchor: '#messages',
      name: 'Messages'
    },
    {
      anchor: '#branding',
      name: 'Branding'
    },
    {
      anchor: '#dashboard',
      name: 'Dashboard'
    },
    {
      anchor: '#modals',
      name: 'Modals'
    },
    {
      anchor: '#progress_bar',
      name: 'Progress Bar'
    },
    {
      anchor: '#logos',
      name: 'Logos'
    }
  ];

  /* eslint-disable max-len */

  return <div className="cf-app cf-sg-layout cf-app-segment cf-app-segment--alt">
    <StickyNav>
      {
        componentLinks.map((link, i) => (
          <NavLink anchor={link.anchor} name={link.name} key={i}/>
        ))
      }
    </StickyNav>
    <div className="cf-sg-content">
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
      <StyleGuideTypography />
      <div className="cf-help-divider"></div>
      <StyleGuidePlaceholder
        title="Headings and Body"
        id="headings_and_body"
        isSubsection={true} />
      <StyleGuidePlaceholder
        title="Styles"
        id="styles"
        isSubsection={true} />
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
      <StyleGuideSmallLoader />
      <div className="cf-help-divider"></div>
      <StyleGuideLoadingButton />
      <div className="cf-help-divider"></div>
      <StyleGuideAlerts />
      <div className="cf-help-divider"></div>
      <StyleGuideLayout />
      <div className="cf-help-divider"></div>
      <StyleGuideMessages />
      <div className="cf-help-divider"></div>
      <StyleGuidePlaceholder
        title="Branding"
        id="branding" />
      <div className="cf-help-divider"></div>
      <StyleGuideDashboard />
      <div className="cf-help-divider"></div>
      <StyleGuideModal />
      <div className="cf-help-divider"></div>
      <StyleGuideProgressBar />
      <div className="cf-help-divider"></div>
      <StyleGuideLogos />
    </div>
  </div>;

}

/* eslint-enable max-len */

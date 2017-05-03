import React from 'react';
import StyleGuideModal from './StyleGuideModal';
import StyleGuideTabs from './StyleGuideTabs';
import StyleGuideProgressBar from './StyleGuideProgressBar';
import StyleGuideLoadingButton from './StyleGuideLoadingButton';
import StyleGuideLinkButton from './StyleGuideLinkButton';
import StyleGuideRadioField from './StyleGuideRadioField';
import StyleGuideCheckboxes from './StyleGuideCheckboxes';
import StyleGuideTables from './StyleGuideTables';
import StyleGuideInlineForm from './StyleGuideInlineForm';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StickyNav from '../../components/StickyNav';
import NavLink from '../../components/NavLink';
import StyleGuideUserDropdownMenu from './StyleGuideUserDropdownMenu';
import StyleGuideNavigationBar from './StyleGuideNavigationBar';
import StyleGuideSearchableDropdown from './StyleGuideSearchableDropdown';
import StyleGuideMessages from './StyleGuideMessages';
import StyleGuideLogos from './StyleGuideLogos';
import StyleGuideColors from './StyleGuideColors';
import StyleGuideLayout from './StyleGuideLayout';

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
      anchor: '#dropdown',
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
      anchor: '#forms_fields',
      name: 'Forms Fields'
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

  return <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt">
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
        <StyleGuidePlaceholder
          title="Typography"
          id="typography" />
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
        <StyleGuidePlaceholder
          title="Buttons"
          id="buttons" />
        <StyleGuideLinkButton />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Search"
          id="search" />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Dropdown Menus"
          id="dropdown" />
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
        <StyleGuidePlaceholder
          title="Accordions"
          id="accordions" />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Forms Fields"
          id="forms_fields" />
        <StyleGuidePlaceholder
          title="Text Input"
          id="text_input"
          isSubsection={true} />
        <StyleGuideInlineForm />
        <div className="cf-help-divider"></div>
        <StyleGuideLoadingButton />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Alerts"
          id="alerts" />
        <div className="cf-help-divider"></div>
        <StyleGuideLayout />
        <div className="cf-help-divider"></div>
        <StyleGuideNavigationBar />
        <StyleGuideUserDropdownMenu />
        <div className="cf-help-divider"></div>
        <StyleGuideMessages />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Branding"
          id="branding" />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Dashboard"
          id="dashboard" />
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

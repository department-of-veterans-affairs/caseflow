import React from 'react';
import StyleGuideModal from './StyleGuideModal';
import StyleGuideTabs from './StyleGuideTabs';
import StyleGuideProgressBar from './StyleGuideProgressBar';
import StyleGuideButton from './StyleGuideButton';
import StyleGuideRadioField from './StyleGuideRadioField';
import StyleGuideCheckboxes from './StyleGuideCheckboxes';
import StyleGuideTables from './StyleGuideTables';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideMessages from './StyleGuideMessages';
import StickyNav from '../../components/StickyNav';
import NavLink from '../../components/NavLink';
import ChildNavLink from '../../components/ChildNavLink';
import StyleGuideSearch from './StyleGuideSearch';
import StyleGuideSearchableDropdown from './StyleGuideSearchableDropdown';
import StyleGuideLogos from './StyleGuideLogos';
import StyleGuideColors from './StyleGuideColors';
import StyleGuideLoaders from './StyleGuideLoaders';
import StyleGuideLayout from './StyleGuideLayout';
import StyleGuideDashboard from './StyleGuideDashboard';
import StyleGuideTypography from './StyleGuideTypography';
import StyleGuideFormFields from './StyleGuideFormFields';
import StyleGuideAccordions from './StyleGuideAccordions';
import StyleGuideAlerts from './StyleGuideAlerts';

export const componentLinks = [
  {
    anchor: '/styleguide#',
    name: 'Introduction'
  },
  {
    anchor: '#branding',
    name: 'Branding',
    subnav: [{
      anchor: '#logos',
      name: 'Logos'
    }]
  },
  {
    anchor: '#typography',
    name: 'Typography',
    subnav: [{
      anchor: '#text_styles',
      name: 'Text Styles'
    },
    {
      anchor: '#font_family',
      name: 'Font Family'
    },
    {
      anchor: '#text_accessibility',
      name: 'Text Accessibility'
    }]
  },
  {
    anchor: '#colors',
    name: 'Colors',
    subnav: [{
      anchor: '#platte',
      name: 'Platte'
    },
    {
      anchor: '#logos',
      name: 'logos'
    }]
  },
  {
    anchor: '#buttons',
    name: 'Buttons',
    subnav: [{
      anchor: '#primary',
      name: 'primary'
    },
    {
      anchor: '#secondary',
      name: 'secondary'
    },
    {
      anchor: '#Disabled',
      name: 'Disabled'
    },
    {
      anchor: '#link_buttons',
      name: 'Link Buttons'
    },
    {
      anchor: '#toggle_buttons',
      name: 'Toggle Buttons'
    }]
  },
  {
    anchor: '#search',
    name: 'Search'
  },
  {
    anchor: '#dropdowns',
    name: 'Dropdown Menus',
    subnav: [{
      anchor: '#single_selection',
      name: 'Search Single Selection'
    },
    {
      anchor: '#multiple_selection',
      name: 'Create and Search Multiple Selection'
    }]
  },
  {
    anchor: '#checkboxes',
    name: 'Checkboxes',
    subnav: [{
      anchor: '#single',
      name: 'Single'
    },
    {
      anchor: '#vertical',
      name: 'Vertical'
    },
    {
      anchor: '#horizontal',
      name: 'Horizontal'
    },
    {
      anchor: '#required',
      name: 'Required'
    },
    {
      anchor: '#acknowledgements',
      name: 'Acknowledgements'
    }]
  },
  {
    anchor: '#radios',
    name: 'Radio Buttons',
    subnav: [{
      anchor: '#vertical',
      name: 'Vertical'
    },
    {
      anchor: '#horizontal',
      name: 'Horizontal'
    }]
  },
  {
    anchor: '#date_input',
    name: 'Date Input'
  },
  {
    anchor: '#tables',
    name: 'Tables',
    subnav: [{
      anchor: '#queues',
      name: 'Queues'
    }]
  },
  {
    anchor: '#tabs',
    name: 'Tabs',
    subnav: [{
      anchor: '#without_icons',
      name: 'Without Icons'
    },
    {
      anchor: '#With_icons',
      name: 'With Icons'
    }]
  },
  {
    anchor: '#accordions',
    name: 'Accordions',
    subnav: [{
      anchor: '#border',
      name: 'Border'
    },
    {
      anchor: '#borderless',
      name: 'Borderless'
    }]
  },
  {
    anchor: '#form_fields',
    name: 'Form Fields',
    subnav: [{
      anchor: '#text_input',
      name: 'Text input'
    },
    {
      anchor: '#text_area',
      name: 'Text area'
    },
    {
      anchor: '#character_limit',
      name: 'Character limit'
    },
    {
      anchor: '#inline_form',
      name: 'Inline Form'
    }]
  },
  {
    anchor: '#loaders',
    name: 'Loaders',
    subnav: [{
      anchor: '#small_loader',
      name: 'Small loader'
    },
    {
      anchor: '#loading_buttons',
      name: 'Loading buttons'
    }]
  },
  {
    anchor: '#alerts',
    name: 'Alerts',
    subnav: [{
      anchor: '#alerts_lite',
      name: 'Alerts lite'
    }]
  },
  {
    anchor: '#layout',
    name: 'Layout',
    subnav: [{
      anchor: '#navigation_bar',
      name: 'Navigation Bar'
    },
    {
      anchor: '#user_dropdown_menu',
      name: 'User dropdown menu'
    },
    {
      anchor: '#content_area',
      name: 'Main content area'
    },
    {
      anchor: '#app_canvas',
      name: 'App canvas'
    },
    {
      anchor: '#actions',
      name: 'Actions'
    },
    {
      anchor: '#horizontal_line',
      name: 'Horizontal line'
    },
    {
      anchor: '#footer',
      name: 'Footer'
    }]
  },
  {
    anchor: '#messages',
    name: 'Messages',
    subnav: [{
      anchor: '#success_messages',
      name: 'Success'
    },
    {
      anchor: '#status_messages',
      name: 'Status'
    },
    {
      anchor: '#alerts',
      name: 'Alert'
    }
    ]
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
  }
];

export default class StyleGuideIndex extends React.Component {

  render() {
    return <div className="cf-app cf-sg-layout cf-app-segment cf-app-segment--alt">
      <StickyNav>
        {
          componentLinks.map((link, i) => (
            <li key={i}>
              <NavLink anchor={link.anchor} name={link.name} />
              { link.subnav && <ChildNavLink links={link.subnav} key={link.name} /> }
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
        <StyleGuideLogos />
        <div className="cf-help-divider"></div>
        <StyleGuideTypography />
        <div className="cf-help-divider"></div>
        <StyleGuidePlaceholder
          title="Headings and Body"
          id="headings_and_body"
          isSubsection />
        <StyleGuidePlaceholder
          title="Styles"
          id="styles"
          isSubsection />
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

      </div>
    </div>;
  }

}

import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Button from '../../components/Button';
import NavigationBar from '../../components/NavigationBar';
import { BrowserRouter as Router } from 'react-router-dom';
import Footer from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '@department-of-veterans-affairs/appeals-frontend-toolkit/util/StyleConstants';

const options = [
  {
    title: 'Help',
    link: '#footer'
  },
  {
    title: 'Send feedback',
    link: '#footer'
  },
  {
    title: 'Sign out',
    link: '#footer'
  }
];

export default class StyleGuideFooter extends React.PureComponent {
  render() {

    return <div>
      <StyleGuideComponentTitle
        title="Footer"
        id="footer"
        link="StyleGuideFooter.jsx"
        isSubsection
      />
      <p>
     All of Caseflow Apps feature a minimal footer that contains the text
    “Built with ♡ by the Digital Service at the VA.” and a “Send Feedback” link.</p>

      <p>
     Conveniently, if a developer hovers over the word
     “Built” they’ll see a tooltip showing the build date
     of the app that they are viewing. In styleguide footer, recent build date
     is based off of “date” in build_version.yml.</p>

      <Router>
        <NavigationBar
          wideApp="full"
          appName="Hearing Prep"
          logoProps={{
            accentColor: LOGO_COLORS.HEARINGS.ACCENT,
            overlapColor: LOGO_COLORS.HEARINGS.OVERLAP
          }}
          userDisplayName="Abraham Lincoln"
          dropdownUrls={options}
          defaultUrl="/"
        />
      </Router>

      <div className="cf-app-segment cf-app-segment--alt"></div>
      <div className="cf-app-segment" id="establish-claim-buttons">
        <div className="cf-push-left">
          <Button
            name="View Work History"
            classNames={['cf-btn-link']}
          />
        </div>
        <div className="cf-push-right">
          <span className="cf-button-associated-text-right">
         30 cases assigned, 5 completed
          </span>
          <Button
            name="Establish Next Claim"
            classNames={['usa-button-primary']}
          />
        </div>
      </div>

      <Footer
        wideApp="full"
        appName="Hearing Prep"
        buildDate="10/01/2017"
        feedbackUrl="#footer" />
    </div>;
  }
}

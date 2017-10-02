import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Button from '../../components/Button';
import NavigationBar from '../../components/NavigationBar';
import { BrowserRouter as Router } from 'react-router-dom';
import Footer from '../../components/Footer';

const options = [
  {
    title: 'Help',
    link: '#navigation_bar'
  },
  {
    title: 'Send feedback',
    link: '#navigation_bar'
  },
  {
    title: 'Sign out',
    link: '#navigation_bar'
  }
];

export default class StyleGuideFooter extends React.Component {
  render() {

    return <div>
      <StyleGuideComponentTitle
        title="Footer"
        id="footer"
        link="StyleGuideFooter.jsx"
        isSubsection={true}
    />
    <p>
     All of Caseflow Apps feature a minimal footer that contains the text
    “Built with ♡ by the Digital Service at the VA.” and a “Send Feedback” link.</p>

    <p>
     Conveniently, if a developer hovers over the word
     “Built” they’ll see a tooltip showing the build date
     of the app that they are viewing.</p>

    <Router>
     <div className="sg-nav-wrap">
       <NavigationBar
        appName="Hearing Prep"
        userDisplayName="Abraham Lincoln"
        dropdownUrls={options}
        defaultUrl="/"
      />
     </div>
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

  <div className="sg-nav-wrap">
   <Footer
    appName="Hearing Prep"
    buildDate="10/01/2017"
    feedbackUrl="#" />
  </div>
</div>;
  }
}

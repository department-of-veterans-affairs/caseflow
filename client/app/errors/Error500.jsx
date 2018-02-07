import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

class Error500 extends React.PureComponent {

  render() {
    const options = [{ title: 'Help',
      link: '/help' },
    { title: 'Switch User',
      link: '/test/users' }];

    return <BrowserRouter>
      <div>
        <NavigationBar
          dropdownUrls={options}
          appName="Error 500"
          userDisplayName="Menu"
          defaultUrl="/"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }} />
        <AppFrame>
          <AppSegment filledBackground>
            <h1 className="cf-red-text cf-msg-screen-heading">Something went wrong.</h1>
            <p className="cf-msg-screen-text">If you continue to see this page, please contact the help desk.</p>
          </AppSegment>
        </AppFrame>
        <Footer
          appName="Help"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate} />
      </div>
    </BrowserRouter>
    ;
  }
}

export default Error500;

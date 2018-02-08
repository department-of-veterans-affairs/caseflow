import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

class Unauthorized extends React.PureComponent {

  render() {
    const options = [{ title: 'Help',
      link: '/help' },
    { title: 'Switch User',
      link: '/test/users' }];

    return <BrowserRouter>
      <div>
        <NavigationBar
          dropdownUrls={options}
          appName="Unauthorized"
          userDisplayName="Menu"
          defaultUrl="/"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }} />
        <AppFrame>
          <StatusMessage>
              <h2 className="cf-msg-screen-heading">Drat!</h2>
              <p className="cf-msg-screen-deck">You aren't authorized to use this part of Caseflow yet.</p>
                 <p className="cf-msg-screen-text">
      <a href="/test/users">
        Switch users to access this page.
      </a>
    </p>
          </StatusMessage>
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

export default Unauthorized;





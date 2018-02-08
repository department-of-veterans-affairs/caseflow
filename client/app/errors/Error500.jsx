import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
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
          <StatusMessage>
            <h1 className="cf-red-text cf-msg-screen-heading">Something went wrong.</h1>
             If you continue to see this page, please contact the help desk.
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

export default Error500;

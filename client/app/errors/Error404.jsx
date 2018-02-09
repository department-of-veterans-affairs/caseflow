import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter, Link } from 'react-router-dom';

class Error404 extends React.PureComponent {

  render() {
    const options = [{ title: 'Help',
      link: '/help' },
    { title: 'Switch User',
      link: '/test/users' }];

    return <BrowserRouter>
      <div>
        <NavigationBar
          dropdownUrls={options}
          appName="Error 404"
          userDisplayName="Menu"
          defaultUrl="/"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }} />
        <AppFrame>
          <StatusMessage title="Page not found">
            Oops! We can't find the correct page. If you need assistance,
            please visit the <Link to="/">Caseflow Help Page</Link>.
            <p>If you continue to see this page, please contact the
              <Link to={this.props.feedbackUrl}>Caseflow Help Desk</Link>.</p>
          </StatusMessage>
        </AppFrame>
        <Footer
          appName="Error 404"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate} />
      </div>
    </BrowserRouter>
    ;
  }
}

export default Error404;

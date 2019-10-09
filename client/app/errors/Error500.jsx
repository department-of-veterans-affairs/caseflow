/* eslint-disable react/prop-types */

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

    let detailedErrorMessage = null;

    if (this.props.flashError) {
      detailedErrorMessage = <React.Fragment>
        <p>Error: <span dangerouslySetInnerHTML={{ __html: this.props.flashError }} /></p>
      </React.Fragment>;
    }

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
          <StatusMessage title="Something went wrong." type="alert">
            If you continue to see this page, please contact the Caseflow team
            via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
            via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.

            <div>Error code: {this.props.errorUUID}</div>

            { detailedErrorMessage }
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

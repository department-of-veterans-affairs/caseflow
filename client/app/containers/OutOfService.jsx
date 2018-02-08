import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

class Unauthorized extends React.PureComponent {

  render() {
    return <BrowserRouter>
      <div>
        <NavigationBar
          dropdownUrls={this.props.dropdownUrls}
          appName="Unauthorized"
          userDisplayName="Menu"
          defaultUrl="/"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }} />
        <AppFrame>
          <StatusMessage title= "Technical Difficulties">
             You aren't authorized to use this part of Caseflow yet.
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


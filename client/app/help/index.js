import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import { COLORS } from '@department-of-veterans-affairs/appeals-frontend-toolkit/util/StyleConstants';
import Footer from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Footer';
import CertificationHelp from './certificationHelp';

class Help extends React.PureComponent {
  render() {

    return <BrowserRouter>
      <div>
        <NavigationBar
          defaultUrl="/"
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          appName="Help"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }}
        >
          <div className="cf-wide-app">
          </div>
        </NavigationBar>
        <Footer
          appName="Help"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate} />
      </div>
    </BrowserRouter>;

  }
}

export default Help;

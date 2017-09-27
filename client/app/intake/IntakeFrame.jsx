import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import First from './pages/first';
import Second from './pages/second';

export default class IntakeFrame extends React.PureComponent {
  render() {
    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    return <Router basename="/intake" {...this.props.routerTestProps}>
      <div>
        <NavigationBar
          appName={appName}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          defaultUrl="/"
        >
        <AppFrame>
          <PageRoute
            exact
            path="/"
            title="Welcome | Caseflow Intake"
            component={First} />
          <PageRoute
            exact
            path="/second"
            title="Welcome 2 | Caseflow Intake"
            component={Second} />
        </AppFrame>
        </NavigationBar>
        <Footer
          appName={appName}
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}
        />
      </div>
    </Router>;
  }
}

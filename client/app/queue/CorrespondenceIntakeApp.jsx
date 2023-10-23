import React from 'react';
import { connect } from 'react-redux';
// import { Switch } from 'react-router-dom';
import ScrollToTop from '../components/ScrollToTop';
// import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import { CorrespondenceIntake } from './correspondence/intake/CorrespondenceIntake';

class CorrespondenceIntakeApp extends React.PureComponent {

  render = () => (
    <NavigationBar
      wideApp
      appName="Intake"
    >
      <AppFrame wideApp>
        <ScrollToTop />
        <div className="cf-wide-app">
          <CorrespondenceIntake />
          {/* Base/page (non-modal) routes */}
          {/* <Switch>
            <PageRoute
              exact
              path="/intake"
              title="Correspondence Intake  | Caseflow"
              render={this.routedQueueList}
            />
          </Switch> */}
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName=""
      />
    </NavigationBar>
  );
}

CorrespondenceIntakeApp.propTypes = {
};

export default connect(
)(CorrespondenceIntakeApp);

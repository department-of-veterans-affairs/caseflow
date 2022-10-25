import React from 'react';
import { BrowserRouter, Switch } from 'react-router-dom';
import PropTypes from 'prop-types';
import PageRoute from '../../components/PageRoute';
import reducers from '../reducers/index';
import NavigationBar from '../../components/NavigationBar';
import { LOGO_COLORS } from '../../constants/AppConstants';
import AppFrame from '../../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
export default class AdminApp extends React.PureComponent {
  render = () => <BrowserRouter basename="/admin">
    <NavigationBar
      wideApp
      defaultUrl="/admin"
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      applicationUrls={this.props.applicationUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT,
      }}
      appName="System Admin"
    >
      <AppFrame wideApp>
        <AppSegment filledBackground>
          <h1>System Admin UI</h1>
          <div />
          <div>
            <Switch>
              <PageRoute
                exact
                path="/admin"
                title="admin"
                render={this.admin}
              />
            </Switch>
          </div>
        </AppSegment>
      </AppFrame>
    </NavigationBar>
    <Footer
      wideApp
      appName=""
      feedbackUrl={this.props.feedbackUrl}
      buildDate={this.props.buildDate}
    />
  </BrowserRouter>
}

export const reducer = reducers;

AdminApp.propTypes = {
  userDisplayName: PropTypes.string.isRequired,
  dropdownUrls: PropTypes.array,
  applicationUrls: PropTypes.array,
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
};

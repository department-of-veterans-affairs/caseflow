import React from 'react';
import { BrowserRouter, Switch } from 'react-router-dom';
import PropTypes from 'prop-types';
import PageRoute from '../../components/PageRoute';
import NavigationBar from '../../components/NavigationBar';
import { LOGO_COLORS } from '../../constants/AppConstants';
import AppFrame from '../../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import GenerateButton from '../components/GenerateButton';
import { sendExtractRequest } from '../actions';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

class AdminApp extends React.PureComponent {
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
              <GenerateButton
                sendExtractRequest={this.props.sendExtractRequest}
                {...this.props.extractReducer}
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

AdminApp.propTypes = {
  userDisplayName: PropTypes.string.isRequired,
  dropdownUrls: PropTypes.array,
  applicationUrls: PropTypes.array,
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  sendExtractRequest: PropTypes.func,
};

const mapStateToProps = (state) => {
  return {
    ...state
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  sendExtractRequest
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AdminApp);

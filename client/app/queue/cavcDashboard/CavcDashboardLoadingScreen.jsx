import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import WindowUtil from '../../util/WindowUtil';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY';
import { fetchAppealDetails } from '../QueueActions';

// Contains the loading screen component and fetches data for the CAVC Dashboard
// The CavcDashboard component is passed through this as a child component for rendering
class CavcDashboardLoadingScreen extends React.PureComponent {
  // loading the appeal instead of the CavcRemand is done because certain parameters from the appeal (ex. veteran
  // name) are not included on the CavcRemand object, but the appealDetails object always includes the remand object
  // LoadingDataDisplay requires a promise; any pre-render loading should be included in createLoadPromise,
  // passed in as an array of promises (or 'thenable' objects)
  createLoadPromise = () => Promise.all([
    this.props.fetchAppealDetails(this.props.appealId)
  ]);

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this CAVC dashboard.<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    // LoadingDataDisplay will resolve the promises passed into createLoadPromise and return them to this
    // component to be saved in the redux store. Once the provided promise object resolves as SUCCESSFUL, it
    // renders the components passed to it as children, in this case the CavcDashboard component
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      key={this.props.appealId}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: COPY.CAVC_DASHBOARD_LOADING_SCREEN_TEXT
      }}
      failStatusMessageProps={{
        title: COPY.CAVC_DASHBOARD_LOADING_FAILURE_TITLE
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return (
      // class names can be added to this div as required for layout/styling
      <div className="usa-grid">
        {loadingDataDisplay}
      </div>
    );
  }
}

CavcDashboardLoadingScreen.propTypes = {
  children: PropTypes.object,
  appealId: PropTypes.string,
  fetchAppealDetails: PropTypes.func,
  appealDetails: PropTypes.object
};

// mappings and connect are boilerplate for connecting to redux and will be added to in the future
// pass state and ownProps into the function when needed to access them as props
const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchAppealDetails
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(CavcDashboardLoadingScreen));

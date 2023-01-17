import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import WindowUtil from '../../util/WindowUtil';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY';
import ApiUtil from '../../util/ApiUtil';
import { prepareAppealForStore } from '../utils';
import { onReceiveAppealDetails } from '../QueueActions';

// Contains the loading screen component and fetches data for the CAVC Dashboard
// The CavcDashboard component is passed through this as a child component for rendering
class CavcDashboardLoadingScreen extends React.PureComponent {
  // placeholder for loading the CavcDashboard object(s) when implemented
  loadDashboard = () => {
    // const { appealId } = this.props;

    // placeholder promise; replace with ApiUtil to get data from cavc_dashboard_controller
    return Promise.resolve(true);
  };

  // loads ONLY the Appeal and AppealDetails that are normally loaded by QueueApp and stores with redux
  // loading the appeal instead of the CavcRemand is done because certain parameters from the appeal (ex. veteran
  // name) are not included on the CavcRemand object, but the appealDetails object always includes the remand object
  loadAppealWithCavcRemand = () => {
    const { appealId } = this.props;

    return (
      ApiUtil.get(`/appeals/${appealId}`).then((response) => {
        this.props.onReceiveAppealDetails(prepareAppealForStore([response.body.appeal]));
      })
    );
  };

  // LoadingDataDisplay requires a promise; any pre-render loading should be included in createLoadPromise,
  // passed in as an array of promises (or 'thenable' objects)
  createLoadPromise = () => Promise.all([this.loadDashboard(), this.loadAppealWithCavcRemand()]);

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this dashboard.<br />
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
        message: 'Loading this case...'
      }}
      failStatusMessageProps={{
        title: COPY.CASE_DETAILS_LOADING_FAILURE_TITLE
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return (
      // class names can be added to this div as required for layout/styling
      <div>
        {loadingDataDisplay}
      </div>
    );
  }
}

CavcDashboardLoadingScreen.propTypes = {
  children: PropTypes.object,
  appealId: PropTypes.string,
  onReceiveAppealDetails: PropTypes.func,
  appealDetails: PropTypes.object
};

// mappings and connect are boilerplate for connecting to redux and will be added to in the future
// pass state and ownProps into the function when needed to access them as props
const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAppealDetails
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(CavcDashboardLoadingScreen));

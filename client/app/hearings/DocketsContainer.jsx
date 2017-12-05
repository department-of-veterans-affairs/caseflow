import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import * as AppConstants from '../constants/AppConstants';
import LoadingContainer from '../components/LoadingContainer';
import StatusMessage from '../components/StatusMessage';
import Dockets from './Dockets';
import ApiUtil from '../util/ApiUtil';

export const getUpcomingHearings = (dispatch) => {
  ApiUtil.get('/hearings/dockets.json', { cache: true }).
    then((response) => {
      dispatch(Actions.populateUpcomingHearings(response.body));
    }, (err) => {
      dispatch(Actions.handleDocketServerError(err));
    });
};

export class DocketsContainer extends React.Component {

  componentDidMount() {
    if (!this.props.upcomingHearings) {
      this.props.getUpcomingHearings();
    }
  }

  render() {

    if (this.props.docketServerError) {
      return <StatusMessage
        title="Unable to load hearings">
          It looks like Caseflow was unable to load hearings.<br />
          Please <a href="">refresh the page</a> and try again.
      </StatusMessage>;
    }

    if (!this.props.upcomingHearings) {
      return <div className="loading-hearings">
        <div className="cf-sg-loader">
          <LoadingContainer color={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}>
            <div className="cf-image-loader">
            </div>
            <p className="cf-txt-c">Loading dockets, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    if (Object.keys(this.props.upcomingHearings).length === 0) {
      return <div>You have no upcoming hearings.</div>;
    }

    return <Dockets {...this.props} />;
  }
}

const mapStateToProps = (state) => ({
  upcomingHearings: state.upcomingHearings,
  docketServerError: state.docketServerError
});

const mapDispatchToProps = (dispatch) => ({
  getUpcomingHearings: () => {
    getUpcomingHearings(dispatch);
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DocketsContainer);

DocketsContainer.propTypes = {
  upcomingHearings: PropTypes.object,
  docketServerError: PropTypes.object
};

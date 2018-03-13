import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import * as Actions from '../actions/Dockets';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingContainer from '../../components/LoadingContainer';
import StatusMessage from '../../components/StatusMessage';
import Dockets from '../Dockets';
import ApiUtil from '../../util/ApiUtil';

export class DocketsContainer extends React.Component {

  getUpcomingHearings = () => {
    ApiUtil.get('/hearings/dockets.json', { cache: true }).then((response) => {
      this.props.dispatch(Actions.populateUpcomingHearings(response.body));
    }, (err) => {
      this.props.dispatch(Actions.handleDocketServerError(err));
    });
  };

  componentDidMount() {
    if (!this.props.upcomingHearings) {
      this.getUpcomingHearings();
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
          <LoadingContainer color={LOGO_COLORS.HEARINGS.ACCENT}>
            <div className="cf-image-loader">
            </div>
            <p className="cf-txt-c">Loading dockets, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    if (_.isEmpty(this.props.upcomingHearings)) {
      return <div>You have no upcoming hearings.</div>;
    }

    return <Dockets {...this.props} />;
  }
}

const mapStateToProps = (state) => ({
  upcomingHearings: state.upcomingHearings,
  docketServerError: state.docketServerError
});

export default connect(
  mapStateToProps
)(DocketsContainer);

DocketsContainer.propTypes = {
  upcomingHearings: PropTypes.object,
  docketServerError: PropTypes.object
};

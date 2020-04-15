import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { HearingsUserContext } from '../contexts/HearingsUserContext';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import HearingDetails from '../components/Details';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';

class HearingDetailsContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hearing: null
    };
  }

  goBack = () => {
    this.props.history.goBack();
  };

  setHearing = (hearing, callback) => {
    this.setState({
      hearing,
      loading: false
    }, callback);
  }

  getHearing = () => {
    const { hearingId } = this.props;
    const { hearings } = this.state;
    const hearing = _.find(hearings, (_hearing) => _hearing.externalId === hearingId);

    if (hearing) {
      this.setHearing(hearing);
    } else {
      return ApiUtil.get(`/hearings/${hearingId}`).then((resp) => {
        this.setHearing(ApiUtil.convertToCamelCase(resp.body.data));
      });
    }
  };

  saveHearing = (data) => {
    const { externalId } = this.state.hearing;

    return ApiUtil.patch(`/hearings/${externalId}`, {
      data: ApiUtil.convertToSnakeCase(data)
    });
  }

  render() {
    const { userInHearingOrTranscriptionOrganization } = this.context;

    return (
      <LoadingDataDisplay
        createLoadPromise={this.getHearing}
        loadingComponentProps={{
          spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
          message: 'Loading the hearing details...'
        }}
        failStatusMessageProps={{
          title: 'Unable to load the details.'
        }}
      >
        <HearingDetails
          disabled={!userInHearingOrTranscriptionOrganization}
          hearing={this.state.hearing}
          setHearing={this.setHearing}
          saveHearing={this.saveHearing}
          goBack={this.goBack}
        />
      </LoadingDataDisplay>
    );
  }
}

HearingDetailsContainer.contextType = HearingsUserContext;

HearingDetailsContainer.propTypes = {
  hearingId: PropTypes.string.isRequired,
  history: PropTypes.object
};

const mapStateToProps = (state) => ({
  hearings: state.hearingSchedule.hearings
});

export default connect(
  mapStateToProps
)(HearingDetailsContainer);

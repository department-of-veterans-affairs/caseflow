import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { HearingsFormContextProvider } from '../contexts/HearingsFormContext';
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

    return ApiUtil.get(`/hearings/${hearingId}`).then((resp) => {
      this.setHearing(ApiUtil.convertToCamelCase(resp.body.data));
    });

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
        <HearingsFormContextProvider hearing={this.state.hearing}>
          <HearingDetails
            disabled={!userInHearingOrTranscriptionOrganization}
            hearing={this.state.hearing}
            setHearing={this.setHearing}
            saveHearing={this.saveHearing}
            goBack={this.goBack}
          />
        </HearingsFormContextProvider>
      </LoadingDataDisplay>
    );
  }
}

HearingDetailsContainer.contextType = HearingsUserContext;

HearingDetailsContainer.propTypes = {
  hearings: PropTypes.array.isRequired,
  hearingId: PropTypes.string.isRequired,
  history: PropTypes.object
};

const mapStateToProps = (state) => ({
  hearings: state.dailyDocket.hearings
});

export default connect(
  mapStateToProps
)(HearingDetailsContainer);

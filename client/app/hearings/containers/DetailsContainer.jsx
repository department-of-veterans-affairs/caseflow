import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';

import HearingDetails from '../components/Details';

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

  getHearing = () => {
    const { hearingId } = this.props;
    const { hearings } = this.state;
    const hearing = _.find(hearings, (_hearing) => _hearing.externalId === hearingId);

    if (hearing) {
      this.setState({ hearing });
    } else {
      return ApiUtil.get(`/hearings/${hearingId}`).then((resp) => {
        this.setState({
          hearing: ApiUtil.convertToCamelCase(resp.body),
          loading: false
        });
      });
    }
  };

  render() {
    return <LoadingDataDisplay
      createLoadPromise={this.getHearing}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
        message: 'Loading the hearing details...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the details.'
      }}>
      <HearingDetails
        disabled={!this.props.userInHearingsOrganization}
        hearing={this.state.hearing}
        goBack={this.goBack}
      />
    </LoadingDataDisplay>;
  }
}

HearingDetailsContainer.propTypes = {
  hearingId: PropTypes.string.isRequired,
  userInHearingsOrganization: PropTypes.bool,
  history: PropTypes.object
};

const mapStateToProps = (state) => ({
  hearings: state.hearingSchedule.hearings
});

export default connect(
  mapStateToProps
)(HearingDetailsContainer);

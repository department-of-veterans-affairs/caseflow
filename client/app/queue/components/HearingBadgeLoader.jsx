import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../../util/ApiUtil';

import HearingBadge from './HearingBadge';
import { setMostRecentlyHeldHearingForAppeal, errorFetchingHearingForAppeal } from '../QueueActions';

class HearingBadgeLoader extends React.PureComponent {
  componentDidMount = () => {
    this.props.setMostRecentlyHeldHearingForAppeal(this.props.externalId, null);

    const requestOptions = {
      withCredentials: true,
      timeout: { response: 5 * 60 * 1000 }
    };

    ApiUtil.get(`/appeals/${this.props.externalId}/hearings`, requestOptions).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setMostRecentlyHeldHearingForAppeal(this.props.externalId, resp.hearings[0]);
    }, (error) => {
      this.props.errorFetchingHearingForAppeal(this.props.externalId, error);
    });
  }

  render = () => {
    if (!this.props.mostRecentlyHeldHearingForAppeal) {
      return null;
    }

    return <HearingBadge hearing={this.props.mostRecentlyHeldHearingForAppeal} />;
  }
}

HearingBadgeLoader.propTypes = {
  task: PropTypes.object.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.task.appeal.externalId;

  return {
    externalId,
    mostRecentlyHeldHearingForAppeal: state.queue.mostRecentlyHeldHearingForAppeal[externalId] || null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setMostRecentlyHeldHearingForAppeal,
  errorFetchingHearingForAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(HearingBadgeLoader);

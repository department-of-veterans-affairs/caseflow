import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../../util/ApiUtil';

import HearingBadge from './HearingBadge';
import { setMostRecentlyHeldHearingForAppeal, errorFetchingHearingForAppeal } from '../QueueActions';

class HearingBadgeLoader extends React.PureComponent {
  componentDidMount = () => {
    this.props.setMostRecentlyHeldHearingForAppeal(this.props.externalId, {});

    ApiUtil.get(`/appeals/${this.props.externalId}/hearings`).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setMostRecentlyHeldHearingForAppeal(this.props.externalId, resp);
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

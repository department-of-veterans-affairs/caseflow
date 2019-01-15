import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';

import HearingDetails from '../Details';

class HearingDetailsContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hearing: null,
      loading: false
    };
  }
  getHearing = () => {
    const { hearingId } = this.props;
    const { hearings } = this.state;
    const hearing = _.find(hearings, (_hearing) => _hearing.id === hearingId);

    if (hearing) {
      this.setState({ hearing });
    } else {
      this.setState({ loading: true });
      ApiUtil.get('/hearing/hearings/:id/worksheet').then((resp) => {
        this.setState({
          hearing: JSON.parse(resp.data),
          loading: false
        });
      });
    }
  }
  render() {
    console.log(this.props);
    if (this.state.hearing) {
      return <HearingDetails hearing={this.state.hearing} />;
    }

    return null;
  }
}

HearingDetailsContainer.propTypes = {
  hearingId: PropTypes.string.isRequired
};

const mapStateToProps = (state) => ({
  hearings: state.hearingSchedule.hearings
});

export default connect(
  mapStateToProps
)(HearingDetailsContainer);

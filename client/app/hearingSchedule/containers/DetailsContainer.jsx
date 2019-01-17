import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';

import HearingDetails from '../components/Details';

class HearingDetailsContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hearing: null,
      loading: false
    };
  }

  componentDidMount() {
    this.getHearing();
  }

  goBack = () => {
    this.props.history.goBack();
  }

  getHearing = () => {
    const { hearingId } = this.props;
    const { hearings } = this.state;
    const hearing = _.find(hearings, (_hearing) => _hearing.externalId === hearingId);

    if (hearing) {
      this.setState({ hearing });
    } else {
      this.setState({ loading: true });
      ApiUtil.get(`/hearings/${hearingId}`).then((resp) => {
        this.setState({
          hearing: ApiUtil.convertToCamelCase(resp.body),
          loading: false
        });
      });
    }
  }
  render() {

    if (this.state.hearing) {
      return <HearingDetails hearing={this.state.hearing} goBack={this.goBack} />;
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

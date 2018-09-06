import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { SEND_TO_LOCATION_MODAL_TYPES } from './constants';
import { showModal } from './uiReducer/uiActions';

class ColocatedSendTaskToTeamView extends React.Component {
  constructor(props) {
    super(props);
    this.props.showModal(SEND_TO_LOCATION_MODAL_TYPES.team);
  }

  render = () => this.props.children;
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showModal
}, dispatch);

export default connect(null, mapDispatchToProps)(ColocatedSendTaskToTeamView);

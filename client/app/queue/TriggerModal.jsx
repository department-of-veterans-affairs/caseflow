import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import { showModal } from './uiReducer/uiActions';

class TriggerModal extends React.Component {
  constructor(props) {
    super(props);
    this.props.showModal(props.modal);
    this.props.history.goBack();
  }

  render = () => null;
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showModal
}, dispatch);

export default (withRouter(connect(null, mapDispatchToProps)(TriggerModal)));

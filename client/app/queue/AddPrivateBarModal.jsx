import * as React from 'react';
import PropTypes from 'prop-types';
import COPY from 'app/../COPY';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { privateBarAdded } from './teamManagement/teamManagement.slice';
import {
  requestSave,
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import TextField from '../components/TextField';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './components/QueueFlowModal';

class AddPrivateBarModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      name: null,
      url: null,
      participant_id: null
    };
  }

  componentDidMount() {
    this.props.resetErrorMessages();
    this.props.resetSuccessMessages();
  }
  componentWillUnmount() {
    this.props.resetErrorMessages();
  }

  submit = () => {
    const options = {
      data: {
        organization: {
          name: this.state.name,
          url: this.state.url,
          participant_id: this.state.participant_id
        }
      }
    };

    return this.props.requestSave('/team_management/private_bar', options).
      then((resp) => this.props.privateBarAdded(resp.body?.org)).
      catch();
  }

  changeName = (value) => this.setState({ name: value });
  changeUrl = (value) => this.setState({ url: value });
  changeParticipantId = (value) => this.setState({ participant_id: value });

  render = () => {
    return <QueueFlowModal
      title={COPY.TEAM_MANAGEMENT_ADD_PRIVATE_BAR_MODAL_TITLE}
      pathAfterSubmit="/team_management"
      submit={this.submit}
    >
      <TextField
        name={COPY.TEAM_MANAGEMENT_NAME_COLUMN_HEADING}
        value={this.state.name}
        onChange={this.changeName}
      />
      <TextField
        name={COPY.TEAM_MANAGEMENT_URL_COLUMN_HEADING}
        value={this.state.url}
        onChange={this.changeUrl}
      />
      <TextField
        name={COPY.TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}
        value={this.state.participant_id}
        onChange={this.changeParticipantId}
      />
    </QueueFlowModal>;
  };
}
AddPrivateBarModal.propTypes = {
  requestSave: PropTypes.func,
  privateBarAdded: PropTypes.func,
  showErrorMessage: PropTypes.func,
};

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  privateBarAdded,
  requestSave,
  resetErrorMessages,
  resetSuccessMessages
}, dispatch);

AddPrivateBarModal.propTypes = {
  requestSave: PropTypes.func,
  onReceiveNewPrivateBar: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  resetSuccessMessages: PropTypes.func
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddPrivateBarModal));

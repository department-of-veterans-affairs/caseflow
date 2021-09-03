import * as React from 'react';
import COPY from '../../COPY.json';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveNewPrivateBar } from './teamManagement/actions';
import {
  requestSave,
  showErrorMessage
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
      then((resp) => this.props.onReceiveNewPrivateBar(resp.body)).
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

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveNewPrivateBar,
  requestSave,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddPrivateBarModal));

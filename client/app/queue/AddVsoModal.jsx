import * as React from 'react';
import PropTypes from 'prop-types';
import COPY from 'app/../COPY';
import RadioField from '../components/RadioField';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { vsoAdded } from './teamManagement/teamManagement.slice';
import {
  requestSave,
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import TextField from '../components/TextField';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './components/QueueFlowModal';

const VSO_CLASS = {
  national: 'national',
  field: 'field'
};

const configForVsoClasses = {
  [VSO_CLASS.national]: { displayText: COPY.TEAM_MANAGEMENT_IHP_WRITING_VSO_OPTION,
    endpoint: 'national_vso' },
  [VSO_CLASS.field]: { displayText: COPY.TEAM_MANAGEMENT_FIELD_VSO_OPTION,
    endpoint: 'field_vso' }
};

class AddVsoModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      name: null,
      url: null,
      participant_id: null,
      classification: VSO_CLASS.national
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

    const endpoint = `/team_management/${configForVsoClasses[this.state.classification].endpoint}`;

    return this.props.requestSave(endpoint, options).
      then((resp) => this.props.vsoAdded(resp.body?.org)).
      catch();
  }

  changeName = (value) => this.setState({ name: value });
  changeUrl = (value) => this.setState({ url: value });
  changeParticipantId = (value) => this.setState({ participant_id: value });
  changeClassification = (value) => this.setState({ classification: value });

  render = () => {
    return <QueueFlowModal
      title={COPY.TEAM_MANAGEMENT_ADD_VSO_MODAL_TITLE}
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
      <RadioField
        vertical
        hideLabel
        name="Choose type of VSO"
        onChange={this.changeClassification}
        value={this.state.classification}
        options={Object.keys(VSO_CLASS).map((classification) => ({ value: classification,
          displayText: configForVsoClasses[classification].displayText }))}
      />
    </QueueFlowModal>;
  };
}

AddVsoModal.propTypes = {
  requestSave: PropTypes.func,
  vsoAdded: PropTypes.func,
  showErrorMessage: PropTypes.func,
};

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  vsoAdded,
  requestSave,
  resetErrorMessages,
  resetSuccessMessages
}, dispatch);

AddVsoModal.propTypes = {
  requestSave: PropTypes.func,
  onReceiveNewVso: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  resetSuccessMessages: PropTypes.func
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddVsoModal));

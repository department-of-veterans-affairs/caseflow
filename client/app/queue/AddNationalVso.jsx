import * as React from 'react';
import editModalBase from './components/EditModalBase';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveNewVso } from './teamManagement/actions';
import {
  requestSave,
  showErrorMessage
} from './uiReducer/uiActions';
import TextField from '../components/TextField';
import { withRouter } from 'react-router-dom';

class AddNationalVso extends React.Component {
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

    return this.props.requestSave('/team_management/national_vso', options).
      then((resp) => this.props.onReceiveNewVso(resp.body)).
      catch((err) => this.props.showErrorMessage({ title: 'Error',
        detail: err }));
  }

  changeName = (value) => this.setState({ name: value });
  changeUrl = (value) => this.setState({ url: value });
  changeParticipantId = (value) => this.setState({ participant_id: value });

  render = () => {
    return <React.Fragment>
      <TextField
        name="Name"
        value={this.state.name}
        onChange={this.changeName}
      />
      <TextField
        name="URL"
        value={this.state.url}
        onChange={this.changeUrl}
      />
      <TextField
        name="BGS Participant ID"
        value={this.state.participant_id}
        onChange={this.changeParticipantId}
      />
    </React.Fragment>;
  };
}

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveNewVso,
  requestSave,
  showErrorMessage
}, dispatch);

const modalOptions = { title: 'Create IHP-writing VSO',
  pathAfterSubmit: '/team_management' };

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(editModalBase(AddNationalVso, modalOptions)));

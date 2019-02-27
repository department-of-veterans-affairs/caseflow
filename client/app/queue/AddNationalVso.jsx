import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import editModalBase from './components/EditModalBase';
import TextField from '../components/TextField';
import { withRouter } from 'react-router-dom';

class AddNationalVso extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      name: null,
      url: null,
      participant_id: null,
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

    return ApiUtil.post('/team_management/national_vso', options).then((resp) => {
      // TODO: Do something with this response.
      });
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

export default withRouter(editModalBase(AddNationalVso, { title: "Create IHP-writing VSO", pathAfterSubmit: '/team_management' }));

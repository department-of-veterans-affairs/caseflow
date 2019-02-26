import { css } from 'glamor';
import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ApiUtil from '../util/ApiUtil';
import Alert from '../components/Alert';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';
import { LOGO_COLORS } from '../constants/AppConstants';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import TextField from '../components/TextField';

export default class TeamManagement extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      judgeTeams: [],
      vsos: [],
      otherOrgs: [],
      loading: true,
      error: null,
    };
  }

  loadingPromise = () => {
    return ApiUtil.get('/team_management').then((response) => {
      const resp = JSON.parse(response.text);

      this.setState({
        judgeTeams: resp.judge_teams,
        vsos: resp.vsos,
        otherOrgs: resp.other_orgs,
        loading: false
      });
    }, (error) => {
      this.setState({
        loading: false,
        error: {
          title: 'Failed to load users',
          body: error.message
        }
      });
    });
  };

  render = () => {
    return <LoadingDataDisplay
      createLoadPromise={this.loadingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading teams...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load Caseflow teams'
      }}>
      {/* TODO: Add errors */}
      <AppSegment filledBackground>
        <div>
          <h1>Caseflow Team Management</h1>

          <table {...tableStyling}>
            <OrgHeader>Judge teams</OrgHeader>
            <OrgList orgs={this.state.judgeTeams} />

            <OrgHeader>VSOs</OrgHeader>
            <OrgList orgs={this.state.vsos} />

            <OrgHeader>Other teams</OrgHeader>
            <OrgList orgs={this.state.otherOrgs} />
          </table>
          

        </div>
      </AppSegment>
    </LoadingDataDisplay>;
  };
}

const tableStyling = css({
  width: '100%',
  '& td': { border: 'none' },
  '& input': { margin: 0 },
});

const labelRowStyling = css({
  '& td': { fontWeight: 'bold' }
});

const sectionStyling = css({
  colspan: 5,
  fontSize: '3rem',
  fontWeight: 'bold'
});

class OrgHeader extends React.PureComponent {
  render = () => {
    return <tr><td {...sectionStyling}>{this.props.children}</td></tr>;
  }
}

class OrgList extends React.PureComponent {
  render = () => {
    return <React.Fragment>
      <tr {...labelRowStyling}>
        <td>ID</td>
        <td>Name</td>
        <td>URL</td>
        <td>BGS Participant ID</td>
        <td></td>
      </tr>
      <tbody>
        { this.props.orgs.map( (org) => <OrgRow {...org} />) }
      </tbody>
    </React.Fragment>;
  }
}

class OrgRow extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      id: props.id,
      name: props.name,
      url: props.url,
      participant_id: props.participant_id
    };
  }

  changeName = (value) => this.setState({ name: value });
  changeUrl = (value) => this.setState({ url: value });
  changeParticipantId = (value) => this.setState({ participant_id: value });

  render = () => {
    return <tr key={this.props.id}>
      <td>{ this.props.id }</td>
      <td>
        <TextField
          value={this.state.name}
          onChange={this.changeName}
          />
      </td>
      <td>
        <TextField
          value={this.state.url}
          onChange={this.changeUrl}
          />
      </td>
      <td>
        <TextField
          value={this.state.participant_id}
          onChange={this.changeParticipantId}
          />
      </td>
      <td>
        
      </td>
    </tr>;
  }
}
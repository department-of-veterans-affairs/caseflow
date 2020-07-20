import Alert from '../components/Alert';
import ApiUtil from '../util/ApiUtil';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../components/Button';
import COPY from '../../COPY';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import PropTypes from 'prop-types';
import React from 'react';
import TextField from '../components/TextField';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { LOGO_COLORS } from '../constants/AppConstants';
import { onReceiveTeamList } from './teamManagement/actions';
import { withRouter } from 'react-router-dom';

const tableStyling = css({
  width: '100%',
  '& td': { border: 'none' },
  '& input': { margin: 0 }
});

class TeamManagement extends React.PureComponent {
  loadingPromise = () => ApiUtil.get('/team_management').then((resp) => this.props.onReceiveTeamList(resp.body));

  addJudgeTeam = () => this.props.history.push('/team_management/add_judge_team');

  addIhpWritingVso = () => this.props.history.push('/team_management/add_vso');

  addPrivateBar = () => this.props.history.push('/team_management/add_private_bar');

  lookupParticipantId = () => this.props.history.push('/team_management/lookup_participant_id');

  render = () => {
    const {
      success,
      error
    } = this.props;

    return <LoadingDataDisplay
      createLoadPromise={this.loadingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading teams...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load Caseflow teams'
      }}>
      <AppSegment filledBackground>
        <div>
          <h1>{COPY.TEAM_MANAGEMENT_PAGE_HEADER}</h1>

          { success && <Alert type="success" title={success.title} message={success.detail} /> }
          { error && <Alert type="error" title={error.title} message={error.detail} /> }

          <table {...tableStyling}>
            <tbody>
              <OrgHeader>
                Judge teams <Button name={COPY.TEAM_MANAGEMENT_ADD_JUDGE_BUTTON} onClick={this.addJudgeTeam} />
              </OrgHeader>
              <OrgList orgs={this.props.judgeTeams} />

              <OrgHeader>
                VSOs <Button name={COPY.TEAM_MANAGEMENT_ADD_VSO_BUTTON} onClick={this.addIhpWritingVso} />
              </OrgHeader>
              <OrgList orgs={this.props.vsos} showBgsParticipantId />

              <OrgHeader>
                Private Bar
                <span {...css({ marginLeft: '1rem' })}>
                  <Button name={COPY.TEAM_MANAGEMENT_ADD_PRIVATE_BAR_BUTTON} onClick={this.addPrivateBar} />
                </span>
                <span {...css({ marginLeft: '1rem' })}>
                  <Button
                    name="Look up Participant ID"
                    onClick={this.lookupParticipantId}
                    classNames={['usa-button-secondary']}
                  />
                </span>
              </OrgHeader>
              <OrgList orgs={this.props.privateBars} showBgsParticipantId />

              <OrgHeader>Other teams</OrgHeader>
              <OrgList orgs={this.props.otherOrgs} />
            </tbody>
          </table>

        </div>
      </AppSegment>
    </LoadingDataDisplay>;
  };
}

TeamManagement.propTypes = {
  error: PropTypes.object,
  history: PropTypes.object,
  judgeTeams: PropTypes.array,
  onReceiveTeamList: PropTypes.func,
  otherOrgs: PropTypes.array,
  privateBars: PropTypes.array,
  success: PropTypes.object,
  vsos: PropTypes.array
};

const mapStateToProps = (state) => {
  const {
    success,
    error
  } = state.ui.messages;

  const {
    judgeTeams,
    privateBars,
    vsos,
    otherOrgs
  } = state.teamManagement;

  return {
    judgeTeams,
    privateBars,
    vsos,
    otherOrgs,
    success,
    error
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({ onReceiveTeamList }, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(TeamManagement));

const sectionHeadingStyling = css({
  fontSize: '3rem',
  fontWeight: 'bold'
});

class OrgHeader extends React.PureComponent {
  render = () => {
    return <tr><td {...sectionHeadingStyling} colSpan="7">{this.props.children}</td></tr>;
  }
}

OrgHeader.propTypes = {
  children: PropTypes.node
};

const labelRowStyling = css({
  '& td': { fontWeight: 'bold' }
});

class OrgList extends React.PureComponent {
  render = () => {
    return <React.Fragment>
      <tr {...labelRowStyling}>
        <td>{COPY.TEAM_MANAGEMENT_ID_COLUMN_HEADING}</td>
        <td>{COPY.TEAM_MANAGEMENT_NAME_COLUMN_HEADING}</td>
        <td>{COPY.TEAM_MANAGEMENT_URL_COLUMN_HEADING}</td>
        <td>{ this.props.showBgsParticipantId && COPY.TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}</td>
        <td></td>
        <td></td>
      </tr>
      { this.props.orgs.map((org) =>
        <OrgRow {...org} key={org.id} showBgsParticipantId={this.props.showBgsParticipantId} />
      ) }
    </React.Fragment>;
  }
}

OrgList.defaultProps = {
  showBgsParticipantId: false
};

OrgList.propTypes = {
  orgs: PropTypes.array,
  showBgsParticipantId: PropTypes.bool
};

class OrgRow extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      id: props.id,
      name: props.name,
      url: props.url,
      participant_id: props.participant_id,
      user_admin_path: props.user_admin_path
    };
  }

  changeName = (value) => this.setState({ name: value });
  changeUrl = (value) => this.setState({ url: value });
  changeParticipantId = (value) => this.setState({ participant_id: value });

  // TODO: Add feedback around whether this request was successful or not.
  submitUpdate = () => {
    const options = {
      data: {
        organization: {
          name: this.state.name,
          url: this.state.url,
          participant_id: this.state.participant_id
        }
      }
    };

    return ApiUtil.patch(`/team_management/${this.props.id}`, options).
      then(() => {
        // TODO: Handle the success

        // const response = JSON.parse(resp.text);/

        // this.props.onReceiveAmaTasks(response.tasks.data);
      }).
      catch(() => {
        // TODO: Handle the error.
        // handle the error from the frontend
      });
  }

  // TODO: Indicate that changes have been made to the row by enabling the submit changes button. Default to disabled.
  render = () => {
    return <tr>
      <td>{ this.props.id }</td>
      <td>
        <TextField
          name={`${COPY.TEAM_MANAGEMENT_NAME_COLUMN_HEADING}-${this.props.id}`}
          label={false}
          useAriaLabel
          value={this.state.name}
          onChange={this.changeName}
        />
      </td>
      <td>
        <TextField
          name={`${COPY.TEAM_MANAGEMENT_URL_COLUMN_HEADING}-${this.props.id}`}
          label={false}
          useAriaLabel
          value={this.state.url}
          onChange={this.changeUrl}
        />
      </td>
      <td>
        { this.props.showBgsParticipantId &&
          <TextField
            name={`${COPY.TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}-${this.props.id}`}
            label={false}
            useAriaLabel
            value={this.state.participant_id}
            onChange={this.changeParticipantId}
          />
        }
      </td>
      <td>
        <Button
          name={COPY.TEAM_MANAGEMENT_UPDATE_ROW_BUTTON}
          id={`${this.props.id}`}
          classNames={['usa-button-secondary']}
          onClick={this.submitUpdate}
        />
      </td>
      <td>
        { this.state.url && <Link to={this.state.user_admin_path}>Org admin page</Link> }
      </td>
    </tr>;
  }
}

OrgRow.defaultProps = {
  showBgsParticipantId: false
};

OrgRow.propTypes = {
  id: PropTypes.number,
  name: PropTypes.string,
  participant_id: PropTypes.number,
  showBgsParticipantId: PropTypes.bool,
  url: PropTypes.string,
  user_admin_path: PropTypes.string
};

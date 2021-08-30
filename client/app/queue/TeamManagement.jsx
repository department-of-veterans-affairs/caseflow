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
import RadioField from '../components/RadioField';
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

const buttonStyling = css({
  marginLeft: '1rem'
});

class TeamManagement extends React.PureComponent {
  loadingPromise = () => ApiUtil.get('/team_management').then((resp) => this.props.onReceiveTeamList(resp.body));

  addJudgeTeam = () => this.props.history.push('/team_management/add_judge_team');

  addDvcTeam = () => this.props.history.push('/team_management/add_dvc_team');

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
              { this.props.dvcTeams && <React.Fragment>
                <OrgHeader>
                  {COPY.TEAM_MANAGEMENT_ADD_DVC_LABEL}
                  <span {...buttonStyling}>
                    <Button name={COPY.TEAM_MANAGEMENT_ADD_DVC_BUTTON} onClick={this.addDvcTeam} />
                  </span>
                </OrgHeader>
                <OrgList orgs={this.props.dvcTeams} />
              </React.Fragment> }

              { this.props.judgeTeams && <React.Fragment>
                <OrgHeader>
                  {COPY.TEAM_MANAGEMENT_ADD_JUDGE_LABEL}
                  <span {...buttonStyling}>
                    <Button name={COPY.TEAM_MANAGEMENT_ADD_JUDGE_BUTTON} onClick={this.addJudgeTeam} />
                  </span>
                </OrgHeader>
                <OrgList orgs={this.props.judgeTeams} showPriorityPushToggles />
              </React.Fragment> }

              { this.props.vsos && <React.Fragment>
                <OrgHeader>
                  {COPY.TEAM_MANAGEMENT_ADD_VSO_LABEL}
                  <span {...buttonStyling}>
                    <Button name={COPY.TEAM_MANAGEMENT_ADD_VSO_BUTTON} onClick={this.addIhpWritingVso} />
                  </span>
                </OrgHeader>
                <OrgList orgs={this.props.vsos} isRepresentative />
              </React.Fragment> }

              { this.props.privateBars && <React.Fragment>
                <OrgHeader>
                  {COPY.TEAM_MANAGEMENT_ADD_PRIVATE_BAR_LABEL}
                  <span {...buttonStyling}>
                    <Button name={COPY.TEAM_MANAGEMENT_ADD_PRIVATE_BAR_BUTTON} onClick={this.addPrivateBar} />
                  </span>
                  <span {...buttonStyling}>
                    <Button
                      name="Look up Participant ID"
                      onClick={this.lookupParticipantId}
                      classNames={['usa-button-secondary']}
                    />
                  </span>
                </OrgHeader>
                <OrgList orgs={this.props.privateBars} isRepresentative />
              </React.Fragment> }

              { this.props.vhaProgramOffices && <React.Fragment>
                <OrgHeader>{COPY.TEAM_MANAGEMENT_ADD_VHA_PROGRAM_OFFICE_TEAM_LABEL}</OrgHeader>
                <OrgList orgs={this.props.vhaProgramOffices} />
              </React.Fragment> }

              { this.props.vhaRegionalOffices && <React.Fragment>
                <OrgHeader>{COPY.TEAM_MANAGEMENT_ADD_VHA_REGIONAL_OFFICE_TEAM_LABEL}</OrgHeader>
                <OrgList orgs={this.props.vhaRegionalOffices} />
              </React.Fragment> }

              { this.props.otherOrgs && <React.Fragment>
                <OrgHeader>{COPY.TEAM_MANAGEMENT_ADD_OTHER_TEAM_LABEL}</OrgHeader>
                <OrgList orgs={this.props.otherOrgs} />
              </React.Fragment> }
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
  dvcTeams: PropTypes.array,
  judgeTeams: PropTypes.array,
  onReceiveTeamList: PropTypes.func,
  otherOrgs: PropTypes.array,
  privateBars: PropTypes.array,
  success: PropTypes.object,
  vsos: PropTypes.array,
  vhaProgramOffices: PropTypes.array,
  vhaRegionalOffices: PropTypes.array
};

const mapStateToProps = (state) => {
  const {
    success,
    error
  } = state.ui.messages;

  const {
    dvcTeams,
    judgeTeams,
    privateBars,
    vsos,
    vhaProgramOffices,
    vhaRegionalOffices,
    otherOrgs
  } = state.teamManagement;

  return {
    dvcTeams,
    judgeTeams,
    privateBars,
    vsos,
    vhaProgramOffices,
    vhaRegionalOffices,
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
        <td>{COPY.TEAM_MANAGEMENT_NAME_COLUMN_HEADING}</td>
        { this.props.showPriorityPushToggles && <td>{COPY.TEAM_MANAGEMENT_PRIORITY_DISTRIBUTION_COLUMN_HEADING}</td> }
        { this.props.isRepresentative && <td>{COPY.TEAM_MANAGEMENT_URL_COLUMN_HEADING}</td> }
        <td>{this.props.isRepresentative && COPY.TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}</td>
        <td></td>
        <td></td>
      </tr>
      { this.props.orgs.map((org) =>
        <OrgRow
          {...org}
          key={org.id}
          isRepresentative={this.props.isRepresentative}
          showPriorityPushToggles={this.props.showPriorityPushToggles}
        />
      ) }
    </React.Fragment>;
  }
}

OrgList.defaultProps = {
  isRepresentative: false,
  showPriorityPushToggles: false
};

OrgList.propTypes = {
  orgs: PropTypes.array,
  isRepresentative: PropTypes.bool,
  showPriorityPushToggles: PropTypes.bool
};

const orgRowStyling = css({
  '&:last_child': { textAlign: 'right' }
});

class OrgRow extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      accepts_priority_pushed_cases: props.accepts_priority_pushed_cases,
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

  changePriorityPush = (judgeTeamId, priorityPush) => {
    const payload = {
      data: {
        organization: {
          accepts_priority_pushed_cases: priorityPush === 'true'
        }
      }
    };

    return ApiUtil.patch(`/team_management/${judgeTeamId}`, payload).
      then((resp) => {
        this.setState({ accepts_priority_pushed_cases: resp.body.org.accepts_priority_pushed_cases });
      });
  };

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
    const priorityPushRadioOptions = [
      {
        displayText: 'Available',
        value: true,
        disabled: !this.state.accepts_priority_pushed_cases && !this.props.current_user_can_toggle_priority_pushed_cases
      }, {
        displayText: 'Unavailable',
        value: false,
        disabled: this.state.accepts_priority_pushed_cases && !this.props.current_user_can_toggle_priority_pushed_cases
      }
    ];

    return <tr {...orgRowStyling}>
      <td>
        <TextField
          name={`${COPY.TEAM_MANAGEMENT_NAME_COLUMN_HEADING}-${this.props.id}`}
          label={false}
          useAriaLabel
          value={this.state.name}
          onChange={this.changeName}
          readOnly={!this.props.isRepresentative}
        />
      </td>
      { this.props.showPriorityPushToggles && <td>
        <RadioField
          id={`priority-push-${this.props.id}`}
          options={priorityPushRadioOptions}
          value={this.state.accepts_priority_pushed_cases}
          onChange={(option) => this.changePriorityPush(this.props.id, option)}
        />
      </td> }
      { this.props.isRepresentative && <td>
        <TextField
          name={`${COPY.TEAM_MANAGEMENT_URL_COLUMN_HEADING}-${this.props.id}`}
          label={false}
          useAriaLabel
          value={this.state.url}
          onChange={this.changeUrl}
          readOnly={!this.props.isRepresentative}
        />
      </td> }
      { !this.props.isRepresentative && !this.props.showPriorityPushToggles && <td></td> }
      <td>
        { this.props.isRepresentative &&
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
        { this.props.isRepresentative &&
          <Button
            name={COPY.TEAM_MANAGEMENT_UPDATE_ROW_BUTTON}
            id={`${this.props.id}`}
            classNames={['usa-button-secondary']}
            onClick={this.submitUpdate}
          />
        }
      </td>
      <td>
        { this.state.url && this.state.user_admin_path && <Link to={this.state.user_admin_path}>
          <Button
            name="Org Admin Page"
            classNames={['usa-button-secondary']}
          />
        </Link> }
      </td>
    </tr>;
  }
}

OrgRow.defaultProps = {
  isRepresentative: false,
  showPriorityPushToggles: false
};

OrgRow.propTypes = {
  accepts_priority_pushed_cases: PropTypes.bool,
  current_user_can_toggle_priority_pushed_cases: PropTypes.bool,
  id: PropTypes.number,
  name: PropTypes.string,
  participant_id: PropTypes.number,
  isRepresentative: PropTypes.bool,
  showPriorityPushToggles: PropTypes.bool,
  url: PropTypes.string,
  user_admin_path: PropTypes.string
};

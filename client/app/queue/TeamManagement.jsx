import React from 'react';
import PropTypes from 'prop-types';

import Alert from '../components/Alert';
import ApiUtil from '../util/ApiUtil';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../components/Button';
import COPY from '../../COPY';

import LoadingDataDisplay from '../components/LoadingDataDisplay';

import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { LOGO_COLORS } from '../constants/AppConstants';
import { onReceiveTeamList } from './teamManagement/actions';
import { withRouter } from 'react-router-dom';
import { OrgHeader } from './teamManagement/OrgHeader';
import { OrgList } from './teamManagement/OrgList';

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
  vhaProgramOffices: PropTypes.array
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
    otherOrgs
  } = state.teamManagement;

  return {
    dvcTeams,
    judgeTeams,
    privateBars,
    vsos,
    vhaProgramOffices,
    otherOrgs,
    success,
    error
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({ onReceiveTeamList }, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(TeamManagement));


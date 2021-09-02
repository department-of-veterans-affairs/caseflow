import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { useDispatch, useSelector } from 'react-redux';
import { useHistory } from 'react-router-dom';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import LoadingDataDisplay from 'app/components/LoadingDataDisplay';
import { LOGO_COLORS } from 'app/constants/AppConstants';
import Alert from 'app/components/Alert';
import Button from 'app/components/Button';
import ApiUtil from 'app/util/ApiUtil';
import { onReceiveTeamList } from './actions';
import { OrgHeader } from './OrgHeader';
import { OrgList } from './OrgList';

import {
  TEAM_MANAGEMENT_PAGE_HEADER,
  TEAM_MANAGEMENT_ADD_DVC_LABEL,
  TEAM_MANAGEMENT_ADD_DVC_BUTTON,
  TEAM_MANAGEMENT_ADD_JUDGE_LABEL,
  TEAM_MANAGEMENT_ADD_JUDGE_BUTTON,
  TEAM_MANAGEMENT_ADD_VSO_LABEL,
  TEAM_MANAGEMENT_ADD_VSO_BUTTON,
  TEAM_MANAGEMENT_ADD_PRIVATE_BAR_LABEL,
  TEAM_MANAGEMENT_ADD_PRIVATE_BAR_BUTTON,
  TEAM_MANAGEMENT_ADD_VHA_PROGRAM_OFFICE_TEAM_LABEL,
  TEAM_MANAGEMENT_ADD_OTHER_TEAM_LABEL,
} from 'app/../COPY';
import { OrgSection } from './OrgSection';

const buttonStyling = css({
  marginLeft: '1rem'
});

export const TeamManagement = React.memo(({
  error,
  success,
  loadingPromise,
  dvcTeams,
  judgeTeams,
  vsos,
  privateBars,
  vhaProgramOffices,
  otherOrgs,
  onAddDvcTeam,
  onAddJudgeTeam,
  onAddIhpWritingVso,
  onAddPrivateBar,
  onLookupParticipantId,
}) => {
  const handleAddDvcTeam = () => onAddDvcTeam?.();
  const handleAddJudgeTeam = () => onAddJudgeTeam?.();
  const handleAddIhpWritingVso = () => onAddIhpWritingVso?.();
  const handleAddPrivateBar = () => onAddPrivateBar?.();
  const handleLookupParticipantId = () => onLookupParticipantId?.();

  return (
    <LoadingDataDisplay
      createLoadPromise={loadingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading teams...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load Caseflow teams'
      }}>
      <AppSegment filledBackground>
        <div>
          <h1>{TEAM_MANAGEMENT_PAGE_HEADER}</h1>

          { success && <Alert type="success" title={success.title} message={success.detail} /> }
          { error && <Alert type="error" title={error.title} message={error.detail} /> }

          { dvcTeams && <OrgSection>
            <OrgHeader>
              {TEAM_MANAGEMENT_ADD_DVC_LABEL}
              <span {...buttonStyling}>
                <Button name={TEAM_MANAGEMENT_ADD_DVC_BUTTON} onClick={handleAddDvcTeam} />
              </span>
            </OrgHeader>
            <OrgList orgs={dvcTeams} />
          </OrgSection> }

          { judgeTeams && <OrgSection>
            <OrgHeader>
              {TEAM_MANAGEMENT_ADD_JUDGE_LABEL}
              <span {...buttonStyling}>
                <Button name={TEAM_MANAGEMENT_ADD_JUDGE_BUTTON} onClick={handleAddJudgeTeam} />
              </span>
            </OrgHeader>
            <OrgList orgs={judgeTeams} showDistributionToggles />
          </OrgSection> }

          { vsos && <OrgSection>
            <OrgHeader>
              {TEAM_MANAGEMENT_ADD_VSO_LABEL}
              <span {...buttonStyling}>
                <Button name={TEAM_MANAGEMENT_ADD_VSO_BUTTON} onClick={handleAddIhpWritingVso} />
              </span>
            </OrgHeader>
            <OrgList orgs={vsos} isRepresentative />
          </OrgSection> }

          { privateBars && <OrgSection>
            <OrgHeader>
              {TEAM_MANAGEMENT_ADD_PRIVATE_BAR_LABEL}
              <span {...buttonStyling}>
                <Button name={TEAM_MANAGEMENT_ADD_PRIVATE_BAR_BUTTON} onClick={handleAddPrivateBar} />
              </span>
              <span {...buttonStyling}>
                <Button
                  name="Look up Participant ID"
                  onClick={handleLookupParticipantId}
                  classNames={['usa-button-secondary']}
                />
              </span>
            </OrgHeader>
            <OrgList orgs={privateBars} isRepresentative />
          </OrgSection> }

          { vhaProgramOffices && <OrgSection>
            <OrgHeader>{TEAM_MANAGEMENT_ADD_VHA_PROGRAM_OFFICE_TEAM_LABEL}</OrgHeader>
            <OrgList orgs={vhaProgramOffices} />
          </OrgSection> }

          { otherOrgs && <OrgSection>
            <OrgHeader>{TEAM_MANAGEMENT_ADD_OTHER_TEAM_LABEL}</OrgHeader>
            <OrgList orgs={otherOrgs} />
          </OrgSection> }

        </div>
      </AppSegment>
    </LoadingDataDisplay>
  );
});

TeamManagement.propTypes = {
  loadingPromise: PropTypes.func,
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
  onAddDvcTeam: PropTypes.func,
  onAddJudgeTeam: PropTypes.func,
  onAddIhpWritingVso: PropTypes.func,
  onAddPrivateBar: PropTypes.func,
  onLookupParticipantId: PropTypes.func,
};

export const TeamManagementWrapper = () => {
  const history = useHistory();
  const dispatch = useDispatch();
  const {
    dvcTeams,
    judgeTeams,
    privateBars,
    vsos,
    vhaProgramOffices,
    otherOrgs
  } = useSelector((state) => state.teamManagement);
  const { success, error } = useSelector((state) => state.ui.messages);

  const loadingPromise = () => ApiUtil.get('/team_management').then((resp) => dispatch(onReceiveTeamList(resp.body)));

  const onAddJudgeTeam = () => history.push('/team_management/add_judge_team');

  const onAddDvcTeam = () => history.push('/team_management/add_dvc_team');

  const onAddIhpWritingVso = () => history.push('/team_management/add_vso');

  const onAddPrivateBar = () => history.push('/team_management/add_private_bar');

  const onLookupParticipantId = () => history.push('/team_management/lookup_participant_id');

  const props = {
    dvcTeams,
    judgeTeams,
    privateBars,
    vsos,
    vhaProgramOffices,
    otherOrgs,
    success,
    error,
    loadingPromise,
    onAddDvcTeam,
    onAddJudgeTeam,
    onAddIhpWritingVso,
    onAddPrivateBar,
    onLookupParticipantId,
  };

  return <TeamManagement {...props} />;
};
export default TeamManagementWrapper;


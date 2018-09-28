// @flow
import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import {
  appealWithDetailSelector,
  tasksForAppealAssignedToAttorneySelector,
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import DocketTypeBadge from './components/DocketTypeBadge';
import AttorneyActionsDropdown from './components/AttorneyActionsDropdown';
import JudgeActionsDropdown from './components/JudgeActionsDropdown';
import ColocatedActionsDropdown from './components/ColocatedActionsDropdown';
import GenericTaskActionsDropdown from './components/GenericTaskActionsDropdown';
import CopyTextButton from '../components/CopyTextButton';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';
import StringUtil from '../util/StringUtil';

import { renderLegacyAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import type { Appeal, Task } from './types/models';
import type { State } from './types/state';

const snapshotParentContainerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'flex',
  flexWrap: 'wrap',
  lineHeight: '3rem',
  marginTop: '3rem',
  padding: '2rem 0',
  '& > div': { padding: '0 3rem 0 0' },
  '& > div:not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  '& > div:first-child': { paddingLeft: '3rem' },

  '& .Select': { maxWidth: '100%' }
});

const headingStyling = css({
  marginBottom: '0.5rem'
});

const editButton = css({
  float: 'right'
});

const snapshotChildResponsiveWrapFixStyling = css({
  '@media(max-width: 1200px)': {
    '& > .usa-width-one-half': {
      borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
      margin: '2rem 3rem 0 3rem',
      marginRight: '3rem !important',
      paddingTop: '2rem',
      width: '100%'
    },
    '& > div:nth-child(2)': { borderRight: 'none' }
  }
});

type Params = {|
  appealId: string,
  hideDropdown?: boolean
|};

type Props = Params & {|
  featureToggles: Object,
  userRole: string,
  appeal: Appeal,
  taskAssignedToUser: Task,
  taskAssignedToAttorney: Task,
  taskAssignedToOrganization: Task
|};

export class CaseSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.taskAssignedToUser) {
      const today = moment().startOf('day');
      const dateAssigned = moment(this.props.taskAssignedToUser.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt><dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  getAbbrevName = ({ firstName, lastName } : { firstName: string, lastName: string }) => {
    return `${firstName.substring(0, 1)}. ${lastName}`;
  }

  getActionName = () => {
    const {
      action
    } = this.props.taskAssignedToUser;

    // First see if there is a constant to convert the action, otherwise sentence-ify it
    if (CO_LOCATED_ADMIN_ACTIONS[action]) {
      return CO_LOCATED_ADMIN_ACTIONS[action];
    }

    return StringUtil.snakeCaseToSentence(action);
  }

  taskInstructionsWithLineBreaks = (instructions?: Array<string>) => <React.Fragment>
    {instructions && instructions.map((text, i) => <React.Fragment><span key={i}>{text}</span><br /></React.Fragment>)}
  </React.Fragment>;

  taskInformation = () => {
    const {
      taskAssignedToUser
    } = this.props;

    if (!taskAssignedToUser) {
      return null;
    }

    const assignedByAbbrev = taskAssignedToUser.assignedBy.firstName ?
      this.getAbbrevName(taskAssignedToUser.assignedBy) : null;

    const preparedByAbbrev = taskAssignedToUser.decisionPreparedBy ?
      this.getAbbrevName(taskAssignedToUser.decisionPreparedBy) : null;

    return <React.Fragment>
      { taskAssignedToUser.action &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName()}</dd>
        </React.Fragment> }
      { assignedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { taskAssignedToUser.instructions &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(taskAssignedToUser.instructions)}</dd>
        </React.Fragment> }
      { preparedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{preparedByAbbrev}</dd>
        </React.Fragment> }
    </React.Fragment>;
  }

  legacyTaskInformation = () => {
    // If this is not a task attached to a legacy appeal, use taskInformation.
    if (!this.props.appeal.locationCode) {
      return this.taskInformation();
    }

    const {
      userRole,
      taskAssignedToUser
    } = this.props;

    if (!taskAssignedToUser) {
      return null;
    }

    const assignedByAbbrev = taskAssignedToUser.assignedBy.firstName ?
      this.getAbbrevName(taskAssignedToUser.assignedBy) : null;

    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment>;

    if (!taskAssignedToUser) {
      return assignedToListItem;
    }

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {
      const assignedByFirstName = taskAssignedToUser.assignedBy.firstName;
      const assignedByLastName = taskAssignedToUser.assignedBy.lastName;

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !taskAssignedToUser.documentId)) {
        return assignedToListItem;
      }

      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment>;
      } else if (userRole === USER_ROLE_TYPES.colocated) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[taskAssignedToUser.action]}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(taskAssignedToUser.instructions)}</dd>
        </React.Fragment>;
      }
    }

    return <React.Fragment>
      { taskAssignedToUser.addedByName && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{taskAssignedToUser.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={taskAssignedToUser.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={taskAssignedToUser.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  showActionsSection = (): boolean => {
    if (this.props.hideDropdown) {
      return false;
    }

    const {
      taskAssignedToUser,
      taskAssignedToAttorney,
      taskAssignedToOrganization
    } = this.props;
    const tasks = _.compact([taskAssignedToUser, taskAssignedToAttorney, taskAssignedToOrganization]);

    // users can end up at case details for appeals with no DAS
    // record (!task.taskId). prevent starting checkout flows
    return Boolean(tasks.length && _.every(tasks, (task) => task.taskId));
  }

  render = () => {
    const {
      appeal,
      taskAssignedToUser,
      taskAssignedToOrganization,
      userRole
    } = this.props;
    let CheckoutDropdown = <React.Fragment />;
    const dropdownArgs = { appealId: appeal.externalId };

    if (userRole === USER_ROLE_TYPES.attorney) {
      CheckoutDropdown = <AttorneyActionsDropdown {...dropdownArgs} />;
    } else if (userRole === USER_ROLE_TYPES.judge && this.props.featureToggles.judge_case_review_checkout) {
      CheckoutDropdown = <JudgeActionsDropdown {...dropdownArgs} />;
    } else if (userRole === USER_ROLE_TYPES.colocated) {
      CheckoutDropdown = <ColocatedActionsDropdown {...dropdownArgs} />;
    } else {
      CheckoutDropdown = <GenericTaskActionsDropdown {...dropdownArgs} />;
    }

    const taskAssignedToVso = taskAssignedToOrganization && taskAssignedToOrganization.assignedTo.type === 'Vso';

    return <div className="usa-grid" {...snapshotParentContainerStyling} {...snapshotChildResponsiveWrapFixStyling}>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</dt>
          <dd>
            {renderLegacyAppealType({
              aod: appeal.isAdvancedOnDocket,
              type: appeal.caseType
            })}
            {!appeal.isLegacyAppeal && <span {...editButton}>
              <Link
                to={`/queue/appeals/${appeal.externalId}/modal/advanced_on_docket_motion`}>
                Edit
              </Link>
            </span>}
          </dd>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</dt>
          <dd><DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}</dd>
          { !taskAssignedToVso && appeal.assignedJudge &&
            <React.Fragment>
              <dt>{COPY.CASE_SNAPSHOT_ASSIGNED_JUDGE_LABEL}</dt>
              <dd>{appeal.assignedJudge.full_name}</dd>
            </React.Fragment> }
          { !taskAssignedToVso && appeal.assignedAttorney &&
            <React.Fragment>
              <dt>{COPY.CASE_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL}</dt>
              <dd>{appeal.assignedAttorney.full_name}</dd>
            </React.Fragment> }
          {this.daysSinceTaskAssignmentListItem()}
          { taskAssignedToUser && taskAssignedToUser.documentId &&
            <React.Fragment>
              <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt>
              <dd><CopyTextButton text={taskAssignedToUser.documentId} /></dd>
            </React.Fragment> }
        </CaseDetailsDescriptionList>
      </div>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          {this.legacyTaskInformation()}
        </CaseDetailsDescriptionList>
      </div>
      {this.showActionsSection() &&
        <div className="usa-width-one-half">
          <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
          {CheckoutDropdown}
        </div>
      }
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { featureToggles, userRole } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    taskAssignedToUser: tasksForAppealAssignedToUserSelector(state, { appealId: ownProps.appealId })[0],
    taskAssignedToAttorney: tasksForAppealAssignedToAttorneySelector(state, { appealId: ownProps.appealId })[0],
    taskAssignedToOrganization: incompleteOrganizationTasksByAssigneeIdSelector(state,
      { appealId: ownProps.appealId })[0]
  };
};

export default connect(mapStateToProps)(CaseSnapshot);

// @flow
import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';

import {
  appealWithDetailSelector,
  getActionableTasksForAppeal
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import DocketTypeBadge from './components/DocketTypeBadge';
import ActionsDropdown from './components/ActionsDropdown';
import OnHoldLabel from './components/OnHoldLabel';
import CopyTextButton from '../components/CopyTextButton';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';
import StringUtil from '../util/StringUtil';

import {
  renderLegacyAppealType,
  taskIsOnHold
} from './utils';
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
  actionableTasks: Array<Task>,
  firstActionableTask: Task,
  featureToggles: Object,
  userRole: string,
  appeal: Appeal
|};

export class CaseSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.firstActionableTask) {
      const today = moment().startOf('day');
      const dateAssigned = moment(this.props.firstActionableTask.assignedOn);
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
    } = this.props.firstActionableTask;

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
      firstActionableTask
    } = this.props;

    if (!firstActionableTask) {
      return null;
    }

    const assignedByAbbrev = firstActionableTask.assignedBy.firstName ?
      this.getAbbrevName(firstActionableTask.assignedBy) : null;

    const preparedByAbbrev = firstActionableTask.decisionPreparedBy ?
      this.getAbbrevName(firstActionableTask.decisionPreparedBy) : null;

    return <React.Fragment>
      { firstActionableTask.action &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName()}</dd>
        </React.Fragment> }
      { assignedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { taskIsOnHold(firstActionableTask) &&
        <React.Fragment>
          <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
          <dd><OnHoldLabel task={firstActionableTask} /></dd>
        </React.Fragment>
      }
      { firstActionableTask.instructions &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(firstActionableTask.instructions)}</dd>
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
      firstActionableTask
    } = this.props;

    if (!firstActionableTask) {
      return null;
    }

    const assignedByAbbrev = firstActionableTask.assignedBy.firstName ?
      this.getAbbrevName(firstActionableTask.assignedBy) : null;

    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment>;

    if (!firstActionableTask) {
      return assignedToListItem;
    }

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {
      const assignedByFirstName = firstActionableTask.assignedBy.firstName;
      const assignedByLastName = firstActionableTask.assignedBy.lastName;

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !firstActionableTask.documentId)) {
        return assignedToListItem;
      }

      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment>;
      } else if (userRole === USER_ROLE_TYPES.colocated) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[firstActionableTask.action]}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
          { taskIsOnHold(firstActionableTask) &&
            <React.Fragment>
              <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
              <dd><OnHoldLabel task={firstActionableTask} /></dd>
            </React.Fragment>
          }
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(firstActionableTask.instructions)}</dd>
        </React.Fragment>;
      }
    }

    return <React.Fragment>
      { firstActionableTask.addedByName && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{firstActionableTask.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={firstActionableTask.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={firstActionableTask.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  render = () => {
    const {
      actionableTasks,
      firstActionableTask,
      appeal
    } = this.props;
    const taskAssignedToVso = firstActionableTask && firstActionableTask.assignedTo.type === 'Vso';

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
          { firstActionableTask && firstActionableTask.documentId &&
            <React.Fragment>
              <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt>
              <dd><CopyTextButton text={firstActionableTask.documentId} /></dd>
            </React.Fragment> }
          { !taskAssignedToVso && !taskAssignedToUser &&
            taskAssignedToOrganization && taskAssignedToOrganization.documentId &&
            <React.Fragment>
              <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt>
              <dd><CopyTextButton text={taskAssignedToOrganization.documentId} /></dd>
            </React.Fragment> }
        </CaseDetailsDescriptionList>
      </div>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          {this.legacyTaskInformation()}
        </CaseDetailsDescriptionList>
      </div>
      { actionableTasks && actionableTasks.length &&
        <div className="usa-width-one-half">
          <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
          <ActionsDropdown task={firstActionableTask} appealId={appeal.externalId} />
        </div>
      }
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { featureToggles, userRole } = state.ui;

  const actionableTasks = getActionableTasksForAppeal(state, { appealId: ownProps.appealId });
  const firstActionableTask = actionableTasks ? actionableTasks[0] : null;

  return {
    actionableTasks,
    firstActionableTask,
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole
  };
};

export default connect(mapStateToProps)(CaseSnapshot);

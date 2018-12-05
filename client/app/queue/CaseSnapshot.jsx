// @flow
import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';

import {
  actionableTasksForAppeal,
  appealWithDetailSelector
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
  featureToggles: Object,
  userRole: string,
  appeal: Appeal,
  primaryTask: Task,
  taskAssignedToUser: Task,
  canEditAod: Boolean
|};

export class CaseSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.primaryTask) {
      const today = moment().startOf('day');
      const dateAssigned = moment(this.props.primaryTask.assignedOn);
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
      label
    } = this.props.primaryTask;

    // First see if there is a constant to convert the label, otherwise sentence-ify it
    if (CO_LOCATED_ADMIN_ACTIONS[label]) {
      return CO_LOCATED_ADMIN_ACTIONS[label];
    }

    return StringUtil.snakeCaseToSentence(label);
  }

  taskInstructionsWithLineBreaks = (instructions?: Array<string>) => <React.Fragment>
    {instructions && instructions.map((text, i) => <React.Fragment><span key={i}>{text}</span><br /></React.Fragment>)}
  </React.Fragment>;

  taskInformation = () => {
    const {
      primaryTask
    } = this.props;

    if (!primaryTask) {
      return null;
    }

    const assignedByAbbrev = primaryTask.assignedBy.firstName ?
      this.getAbbrevName(primaryTask.assignedBy) : null;

    const preparedByAbbrev = primaryTask.decisionPreparedBy ?
      this.getAbbrevName(primaryTask.decisionPreparedBy) : null;

    return <React.Fragment>
      { primaryTask.label &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName()}</dd>
        </React.Fragment> }
      { assignedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { taskIsOnHold(primaryTask) &&
        <React.Fragment>
          <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
          <dd><OnHoldLabel task={primaryTask} /></dd>
        </React.Fragment>
      }
      { primaryTask.instructions &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(primaryTask.instructions)}</dd>
        </React.Fragment> }
      { preparedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{preparedByAbbrev}</dd>
        </React.Fragment> }
    </React.Fragment>;
  }

  legacyTaskInformation = () => {
    // If this is not a task attached to a legacy appeal, use taskInformation.
    if (!this.props.appeal.isLegacyAppeal) {
      return this.taskInformation();
    }

    const {
      userRole,
      primaryTask
    } = this.props;

    if (!primaryTask) {
      return null;
    }

    const assignedByAbbrev = primaryTask.assignedBy.firstName ?
      this.getAbbrevName(primaryTask.assignedBy) : null;

    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment>;

    // TODO: Can we ever exucute this block? Doesn't the exact same condition above kick us out of this function
    // before we ever reach this point?
    if (!primaryTask) {
      return assignedToListItem;
    }

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {
      const assignedByFirstName = primaryTask.assignedBy.firstName;
      const assignedByLastName = primaryTask.assignedBy.lastName;

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !primaryTask.documentId)) {
        return assignedToListItem;
      }

      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment>;
      } else if (userRole === USER_ROLE_TYPES.colocated) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[primaryTask.label]}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
          { taskIsOnHold(primaryTask) &&
            <React.Fragment>
              <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
              <dd><OnHoldLabel task={primaryTask} /></dd>
            </React.Fragment>
          }
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(primaryTask.instructions)}</dd>
        </React.Fragment>;
      }
    }

    return <React.Fragment>
      { primaryTask.addedByName && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{primaryTask.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={primaryTask.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={primaryTask.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  showActionsSection = (): boolean => {
    if (this.props.hideDropdown) {
      return false;
    }

    const {
      userRole,
      primaryTask
    } = this.props;

    if (!primaryTask) {
      return false;
    }

    // users can end up at case details for appeals with no DAS
    // record (!task.taskId). prevent starting attorney checkout flows
    return userRole === USER_ROLE_TYPES.judge ? Boolean(primaryTask) : Boolean(primaryTask.taskId);
  }

  render = () => {
    const {
      appeal,
      primaryTask
    } = this.props;
    const taskAssignedToVso = primaryTask && primaryTask.assignedTo.type === 'Vso';

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
            {!appeal.isLegacyAppeal && this.props.canEditAod && <span {...editButton}>
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
          { !taskAssignedToVso && primaryTask && primaryTask.documentId &&
            <React.Fragment>
              <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt>
              <dd><CopyTextButton text={primaryTask.documentId} /></dd>
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
          <ActionsDropdown task={primaryTask} appeal={appeal} />
        </div>
      }
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { featureToggles, userRole, canEditAod } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId, appealType: ownProps.appealType }),
    featureToggles,
    userRole,
    primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
    canEditAod
  };
};

export default connect(mapStateToProps)(CaseSnapshot);

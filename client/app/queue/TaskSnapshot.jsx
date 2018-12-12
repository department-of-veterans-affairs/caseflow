import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';

import {
  actionableTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import ActionsDropdown from './components/ActionsDropdown';
import OnHoldLabel from './components/OnHoldLabel';

import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';
import StringUtil from '../util/StringUtil';

import { taskIsOnHold } from './utils';
import { DateString } from '../util/DateUtil';
import type { Appeal, Task } from './types/models';
import type { State } from './types/state';

import { GrayDot } from '../components/RenderFunctions';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling
} from './StickyNavContentArea';

export const grayLine = css({
  width: '5px',
  minHeight: '50px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '35px',
  left: '25px',
  bottom: 0
});

const leftTableCell = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px'
});

const tableCellWithIcon = css({
  textAlign: 'center',
  border: 'none',
  padding: '10px',
  position: 'relative',
  verticalAlign: 'top',
  width: '45px'
});

const tableCell = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px'
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

export class TaskSnapshot extends React.PureComponent<Props> {
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

  taskInstructionsWithLineBreaks = (instructions?: Array<string>) => {
    if (!instructions || !instructions.length) {
      return <br />;
    }

    return <React.Fragment>
      {instructions.map((text, i) => <React.Fragment><span key={i}>{text}</span><br /></React.Fragment>)}
    </React.Fragment>;
  }

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
      <dt>Assigned to</dt><dd>{primaryTask.assignedTo.cssId}</dd>
      { assignedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { preparedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{preparedByAbbrev}</dd>
        </React.Fragment> }
      { primaryTask.label &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName()}</dd>
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

    return <div className="usa-grid" {...css({ marginTop: '3rem' })}>
      <h2 {...sectionHeadingStyling}>
        <a id="our-elemnt" {...anchorJumpLinkStyling}>Currently active tasks</a>
      </h2>
      <div {...sectionSegmentStyling}>
        <table {...css({ width: '100%',
          marginTop: 0 })}>
          <tbody>
            <tr>
              <td {...leftTableCell} {...css({ width: '20%' })}>
                <CaseDetailsDescriptionList>
                  <dt>Assigned on</dt>
                  <dd>{moment(primaryTask.assignedOn).format('MM/DD/YYYY')}</dd>
                  {this.daysSinceTaskAssignmentListItem()}
                </CaseDetailsDescriptionList>
              </td>
              <td {...tableCellWithIcon}><GrayDot /><div {...grayLine} /></td>
              <td {...tableCell} {...css({ width: '25%' })}>
                <CaseDetailsDescriptionList>
                  {this.legacyTaskInformation()}
                </CaseDetailsDescriptionList>
              </td>
              <td {...tableCell} {...css({ width: '50%' })}>
                {this.showActionsSection() &&
                  <React.Fragment>
                    <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
                    <ActionsDropdown task={primaryTask} appealId={appeal.externalId} />
                  </React.Fragment>
                }
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { featureToggles, userRole, canEditAod } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
    canEditAod
  };
};

export default connect(mapStateToProps)(TaskSnapshot);

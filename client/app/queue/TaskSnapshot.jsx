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
import type { Appeal } from './types/models';
import type { State } from './types/state';

import { GrayDot } from '../components/RenderFunctions';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling
} from './StickyNavContentArea';
import Button from '../components/Button';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '25px',
  left: '45%',
  bottom: 0
});

const taskContainerStyling = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  paddingBottom: '3rem'
});

const taskTimeContainerStyling = css(taskContainerStyling, { width: '20%' });
const taskInformationContainerStyling = css(taskContainerStyling, { width: '25%' });
const taskActionsContainerStyling = css(taskContainerStyling, { width: '50%' });

const tableStyling = css({
  width: '100%',
  marginTop: '0px'
});

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 10px 10px',
  position: 'relative',
  verticalAlign: 'top',
  width: '45px'
});

type Params = {|
  appealId: string,
  hideDropdown?: boolean
|};

type Props = Params & {|
  userRole: string,
  appeal: Appeal
|};

export class TaskSnapshot extends React.PureComponent<Props> {
  constructor(props) {
    super(props);
    this.state = {
      taskInstructionsIsVisible: false
    };
  }

  toggleTaskInstructionsVisibility = () => {
    const prevState = this.state.taskInstructionsIsVisible;

    this.setState({ taskInstructionsIsVisible: !prevState });
  }

  daysSinceTaskAssignmentListItem = (task) => {
    if (task) {
      const today = moment().startOf('day');
      const dateAssigned = moment(task.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt>
        <dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  getAbbrevName = ({ firstName, lastName } : { firstName: string, lastName: string }) => {
    return `${firstName.substring(0, 1)}. ${lastName}`;
  }

  getActionName = (task) => {
    const {
      label
    } = task;

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

  taskInformation = (task) => {
    const assignedByAbbrev = task.assignedBy.firstName ?
      this.getAbbrevName(task.assignedBy) : null;
    const preparedByAbbrev = task.decisionPreparedBy ?
      this.getAbbrevName(task.decisionPreparedBy) : null;

    return <React.Fragment>
      <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{task.assignedTo.cssId}</dd>
      { assignedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { preparedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{preparedByAbbrev}</dd>
        </React.Fragment> }
      { task.label &&
        <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName(task)}</dd>
        </React.Fragment> }
      { task.instructions && task.instructions.length > 0 &&
        <div>
          { this.state.taskInstructionsIsVisible &&
          <React.Fragment>
            <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
            <dd>{this.taskInstructionsWithLineBreaks(task.instructions)}</dd>
          </React.Fragment> }
          <Button
            linkStyling
            styling={css({ padding: '0' })}
            name={this.state.taskInstructionsIsVisible ? COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
              COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL}
            onClick={this.toggleTaskInstructionsVisibility} />
        </div>
      }
    </React.Fragment>;
  }

  legacyTaskInformation = (task) => {
    // If this is not a task attached to a legacy appeal, use taskInformation.

    if (!this.props.appeal.isLegacy) {
      return this.taskInformation(task);
    }
    const {
      userRole
    } = this.props;

    const assignedByAbbrev = task.assignedBy.firstName ?
      this.getAbbrevName(task.assignedBy) : null;
    const assignedToListItem = this.props.appeal.locationCode ? <React.Fragment>
      <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment> : null;

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {

      const assignedByFirstName = task.assignedBy.firstName;
      const assignedByLastName = task.assignedBy.lastName;

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !task.documentId)) {
        return assignedToListItem;
      }

      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment>;

      } else if (userRole === USER_ROLE_TYPES.colocated) {

        return <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
          <dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[task.label]}</dd>
          { task.instructions && task.instructions.length > 0 &&
            <div>
              { this.state.taskInstructionsIsVisible &&
              <React.Fragment>
                <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
                <dd>{this.taskInstructionsWithLineBreaks(task.instructions)}</dd>
              </React.Fragment> }
              <Button
                linkStyling
                styling={css({ padding: '0' })}
                name={this.state.taskInstructionsIsVisible ? COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
                  COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL}
                onClick={this.toggleTaskInstructionsVisibility} />
            </div>
          }
        </React.Fragment>;
      }

    }

    return <React.Fragment>
      { task.addedByName && <React.Fragment>
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{task.addedByName}</dd>
      </React.Fragment> }
    </React.Fragment>;
  };

  showActionsSection = (task) => (task && !this.props.hideDropdown);

  render = () => {
    const {
      appeal
    } = this.props;

    let sectionBody = COPY.TASK_SNAPSHOT_NO_ACTIVE_LABEL;
    const taskLength = this.props.tasks.length;

    if (taskLength) {
      sectionBody = this.props.tasks.map((task, index) =>
        <tr>
          <td {...taskTimeContainerStyling}>
            <CaseDetailsDescriptionList>
              { task.assignedOn &&
                <React.Fragment>
                  <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
                  <dd><DateString date={task.assignedOn} dateFormat="MM/DD/YYYY" /></dd>
                </React.Fragment>
              }
              { taskIsOnHold(task) ?
                <React.Fragment>
                  <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
                  <dd><OnHoldLabel task={task} /></dd>
                </React.Fragment> :
                this.daysSinceTaskAssignmentListItem(task)
              }
              { task.dueOn &&
                <React.Fragment>
                  <dt>{COPY.TASK_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
                  <dd><DateString date={task.dueOn} dateFormat="MM/DD/YYYY" /></dd>
                </React.Fragment>
              }
            </CaseDetailsDescriptionList>
          </td>
          <td {...taskInfoWithIconContainer}><GrayDot />
            { (index + 1 < taskLength) && <div {...grayLineStyling} /> }</td>
          <td {...taskInformationContainerStyling}>
            <CaseDetailsDescriptionList>
              {this.legacyTaskInformation(task)}
            </CaseDetailsDescriptionList>
          </td>
          <td {...taskActionsContainerStyling}>
            {this.showActionsSection(task) &&
            <React.Fragment>
              <h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
              <ActionsDropdown task={task} appealId={appeal.externalId} />
            </React.Fragment>
            }
          </td>
        </tr>);
    }

    return <div className="usa-grid" {...css({ marginTop: '3rem' })}>
      <h2 {...sectionHeadingStyling}>
        <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.TASK_SNAPSHOT_ACTIVE_TASKS_LABEL}</a>
      </h2>
      <div {...sectionSegmentStyling}>
        <table {...tableStyling}>
          <tbody>
            { sectionBody }
          </tbody>
        </table>
      </div>
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { userRole } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    userRole,
    tasks: actionableTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);

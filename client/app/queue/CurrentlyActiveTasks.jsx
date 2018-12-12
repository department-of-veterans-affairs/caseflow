import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { GrayDot, GreenCheckmark } from '../components/RenderFunctions';
import moment from 'moment';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import {
  getTasksForAppeal,
  actionableTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import ActionsDropdown from './components/ActionsDropdown';

const grayLine = css({
  width: '5px',
  minHeight: '50px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto'
});

const tableCellWithIcon = css({
  textAlign: 'center',
  border: 'none',
  padding: 0
});

const tableCell = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  fontWeight: 'normal'
});

const tableCellTitle = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  fontWeight: 'bold',
  textTransform: 'uppercase'
});

const getEventRow = ({ assignedOn, assignedTo, assignedBy, type, appealId }, lastRow, showActionsSection) => {
  const today = moment().startOf('day');
  const task = { assignedOn, assignedTo, assignedBy, type };
  const formattedassignedOnDate = assignedOn ? moment(assignedOn).format('MM/DD/YYYY') : null;
  const dayCountSinceAssignment = today.diff(assignedOn, 'days');

  const eventImage = <GrayDot />;

  return <tr key={assignedOn}>
    <table>
      <tr>
        <td {...tableCell}>
          <table>
            <tr><td><ActionsDropdown task={task} appealId={appealId} /></td></tr>

            <tr><td {...tableCellTitle}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL + ": "}</td><td {...tableCell}>{formattedassignedOnDate}</td></tr>
            <tr><td {...tableCellTitle}>{COPY.CASE_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL + ": "}</td><td {...tableCell}>{dayCountSinceAssignment}</td></tr>
          </table>
        </td>
        <td {...tableCell}>
          <table>
            <tr><td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td></tr>
          </table>
        </td>
        <td {...tableCell}>
          <table>
            {/*<tr><td {...tableCellTitle}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL + ": "}</td><td {...tableCell}>{assignedTo.cssId}</td></tr>
            <tr><td {...tableCellTitle}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL + ": "}</td><td {...tableCell}>{assignedBy.firstName + ' ' + assignedBy.lastName}</td></tr>
            <tr><td {...tableCellTitle}>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL + ": "}</td><td {...tableCell}>{type.replace( /([A-Z])/g, " $1" )}</td></tr>
            <tr><td {...tableCellTitle}>{"View task instructions"}</td></tr>*/}
            <tr>
              <td {...tableCellTitle}>
                {COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL + ": "}  <span {...tableCell}>{assignedTo.cssId}</span><br/>
                {COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL + ": "}  <span {...tableCell}>{assignedBy.firstName + ' ' + assignedBy.lastName}</span><br/>
                {COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL + ": "}  <span {...tableCell}>{type}</span><br/>
                <span {...tableCell}>{"View task instructions"}</span><br/>
              </td>
            </tr>
          </table>
        </td>
        <td {...tableCell}>
          <table>
            <tr>
              <td {...tableCellTitle}>
                {showActionsSection &&
                  <div className="usa-width-one-half">
                    <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
                    <ActionsDropdown task={task} appealId={appealId} />
                  </div>
                }
                {/* TODO steal ActionsDropdown from CaseSnapshot */}
                {/*<ActionsDropdown task={primaryTask} appealId={appeal.externalId} />*/}
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>



      {/*<h4 {...tableCellTitle}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL + ": "}</h4>
      <td {...tableCell}>{assignedOn}</td>

      <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>

      <h4 {...tableCellTitle}>{COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE + ": "}</h4>
      <td {...tableCell}>{assignedTo.cssId}</td>

      <h4 {...tableCellTitle}>{COPY.CASE_LIST_TABLE_DAYS_WAITING_COLUMN_TITLE + ": "}</h4>
      <td {...tableCell}>{'8'}</td>*/}


    {/*<h4 {...tableCellTitle}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL + ": "}</h4>
    <td {...tableCell}>{assignedOn}</td>

    <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>

    <h4 {...tableCellTitle}>{COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE + ": "}</h4>
    <td {...tableCell}>{assignedTo.cssId} <br/></td>*/}

    {/*<h4 {...tableCellTitle}>{COPY.CASE_LIST_TABLE_DAYS_WAITING_COLUMN_TITLE + ": "}</h4> DAYS WAITING
    <td {...tableCell}>{}</td>*/}


    {/*<td {...tableCell}>{formattedDate}</td>
    <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>
    <td {...tableCell}>{title}</td> */}
  </tr>;
};

type Props = Params & {|
  incompleteTasks: Array,
  actionableTasks: Array,
  test: string
|};

export class CurrentlyActiveTasks extends React.PureComponent {
  showActionsSection = (): boolean => {
    if (this.props.hideDropdown) {
      return false;
    }
    const {
      userRole,
    } = this.props;

     // users can end up at case details for appeals with no DAS
    // record (!task.taskId). prevent starting attorney checkout flows
    //return userRole === USER_ROLE_TYPES.judge ? Boolean(primaryTask) : Boolean(primaryTask.taskId);
  }

  render = () => {
    const {
      actionableTasks,
      appeal
    } = this.props;

    var showActionsSection = this.showActionsSection();
    console.log('--CurrentlyActiveTasks--');
    console.log(actionableTasks);
    console.log(showActionsSection);

    return <React.Fragment>
      <table>
        <tbody>
          {actionableTasks && actionableTasks.map((event, index) => {
            return getEventRow(event, index === actionableTasks.length - 1, showActionsSection);
          })}
        </tbody>
      </table>
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const { userRole } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    incompleteTasks: getTasksForAppeal(state, { appealId: ownProps.appealId }),
    actionableTasks: actionableTasksForAppeal(state, { appealId: ownProps.appealId }),
    userRole,
    //primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0]
  };
};

export default connect(mapStateToProps)(CurrentlyActiveTasks);

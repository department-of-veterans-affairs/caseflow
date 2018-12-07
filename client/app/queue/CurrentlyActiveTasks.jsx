import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { GrayDot, GreenCheckmark } from '../components/RenderFunctions';
import moment from 'moment';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';
import {
  getTasksForAppeal,
  actionableTasksForAppeal
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

const getEventRow = ({ assignedOn, assignedTo, assignedBy, type }, lastRow) => {
  const today = moment().startOf('day');
  const formattedassignedOnDate = assignedOn ? moment(assignedOn).format('MM/DD/YYYY') : null;
  const dayCountSinceAssignment = today.diff(assignedOn, 'days');

  const eventImage = <GrayDot />;

  return <tr key={assignedOn}>
    <table>
      <tr>
        <td {...tableCell}>
          <table>
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
                Actions <br/>
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
  render = () => {
    const {
      actionableTasks
    } = this.props;

    console.log('--CurrentlyActiveTasks--');
    console.log(actionableTasks);

    return <React.Fragment>
      <table>
        <tbody>
          {actionableTasks && actionableTasks.map((event, index) => {
            return getEventRow(event, index === actionableTasks.length - 1);
          })}
        </tbody>
      </table>
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {

  return {
    incompleteTasks: getTasksForAppeal(state, { appealId: ownProps.appealId }),
    actionableTasks: actionableTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(CurrentlyActiveTasks);

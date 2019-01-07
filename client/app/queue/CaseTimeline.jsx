import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { connect } from 'react-redux';
import type { State } from './types/state';

import { GrayDot, GreenCheckmark } from '../components/RenderFunctions';
import moment from 'moment';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';
import {
  completeTasksSelector,
  actionableTasksForAppeal,
  incompleteTasksSelector
} from './selectors';

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
  '& > dd': { textTransform: 'uppercase' }
});

const tableTitle = css({
  textTransform: 'uppercase',
  fontWeight: 'bold',
  display: 'inline'
});

type Params = {|
  appealId: string
|};

const getEventRow = ({ title, date, assigned_by }, lastRow) => {
  const formattedDate = date ? moment(date).format('MM/DD/YYYY') : null;
  const eventImage = date ? <GreenCheckmark /> : <GrayDot />;

  return <tr key={title}>
    <td {...tableCell}><dd {...tableTitle}>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL}: </dd>{formattedDate}</td>
    <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>
    <td {...tableCell}>
      {title} <br />
      <dt {...tableTitle} >{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}: </dt>
      <dd {...css({ display: 'inline' })}>{assigned_by}</dd>
    </td>
  </tr>;
};

class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal
    } = this.props;

    /* console.log('--completedTasks--');
    console.log(this.props);*/

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table>
        <tbody>
          {appeal.timeline.map((event, index) => {
            return getEventRow(event, index === appeal.timeline.length - 1);
          })}
        </tbody>
      </table>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  return {
    incompletedTasks: incompleteTasksSelector(state, { appealId: ownProps.appealId }),
    completedTasks: completeTasksSelector(state, { appealId: ownProps.appealId }),
    tasks: actionableTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(CaseTimeline);

CaseTimeline.propTypes = {
  appeal: PropTypes.object.isRequired
};

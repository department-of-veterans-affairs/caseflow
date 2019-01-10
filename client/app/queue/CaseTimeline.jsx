import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { connect } from 'react-redux';
import type { State } from './types/state';
import {
  nonRootActionableTasksForAppeal,
  getAllTasksForAppeal,
  completeTasksSelector,
  rootTasksForAppeal,
  appealWithDetailSelector,
  allCompleteTasksForAppeal
} from './selectors';
import { GrayDot, GreenCheckmark } from '../components/RenderFunctions';
import moment from 'moment';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';
import TaskRows from './components/TaskRows';

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

type Props = Params & {|
  appeal: Appeal
|};

const getEventRow = ({ title, date, assigned_to, assigned_by, instructions }, lastRow) => {
  const formattedDate = date ? moment(date).format('MM/DD/YYYY') : null;
  const eventImage = date ? <GreenCheckmark /> : <GrayDot />;

  return <tr key={title}>
    <td {...tableCell}>
      { formattedDate && <React.Fragment>
        <dd {...tableTitle}>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL}: </dd>{formattedDate}
      </React.Fragment> }
    </td>
    <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>
    <td {...tableCell}>
      {title} <br />
      { assigned_to && <React.Fragment>
        <dt {...tableTitle} >{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}: </dt>
        <dd {...css({ display: 'inline' })}>{assigned_to}</dd>
      </React.Fragment> } <br />
      { assigned_by && <React.Fragment>
        <dt {...tableTitle} >{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}: </dt>
        <dd {...css({ display: 'inline' })}>{assigned_by}</dd>
      </React.Fragment> } <br />
      { assigned_by && <React.Fragment>
        <dt {...tableTitle} >{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}: </dt>
        <dd {...css({ display: 'inline' })}>TODO #1</dd>
      </React.Fragment> } <br />
      { instructions && <React.Fragment>
        <dt {...tableTitle} >{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}: </dt>
        <dd {...css({ display: 'inline' })}>TODO #2</dd>
      </React.Fragment> }
    </td>
  </tr>;
};

class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal
    } = this.props;

    console.log('--CaseTimeline--');
    //console.log(this);
    console.log(this.props);
    //console.log(this.props.appeal);
    //console.log(this.props.appeal.timeline);

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table>
        <tbody>
          { /*appeal.timeline.map((event, index) => {
            return getEventRow(event, index === appeal.timeline.length - 1);
          })*/}
          { <TaskRows appeal={appeal} taskList={this.props.completedTasks} /> }
        </tbody>
      </table>
    </React.Fragment>;
  }
}

/*const mapStateToProps = (state: State, ownProps: Params) => {
  return {
    tasks: nonRootActionableTasksForAppeal(state, { appealId: ownProps.appealId }),
    allTasks: getAllTasksForAppeal(state, { appealId: ownProps.appealId }),
    completedTasks: completeTasksSelector(state, { appealId: ownProps.appealId }),
    rootTask: rootTasksForAppeal(state, { appealId: ownProps.appealId })[0]
  };
};

export default connect(mapStateToProps)(CaseTimeline);

CaseTimeline.propTypes = {
  appeal: PropTypes.object.isRequired
};*/

const mapStateToProps = (state: State, ownProps: Params) => {

  return {
    allTasks: getAllTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),
    completedTasks: allCompleteTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),
    //tasks: nonRootActionableTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),


    /*tasks: nonRootActionableTasksForAppeal(state, { appealId: ownProps.appealId }),
    allTasks: getAllTasksForAppeal(state, { appealId: ownProps.appealId }),
    completedTasks: completeTasksSelector(state, { appealId: ownProps.appealId }),
    rootTask: rootTasksForAppeal(state, { appealId: ownProps.appealId })[0]*/
  };
};

export default connect(mapStateToProps)(CaseTimeline);

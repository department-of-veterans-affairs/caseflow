import React from 'react';
import { connect } from 'react-redux';
import COPY from '../../../COPY.json';
import { GrayDot, GreenCheckmark, CancelIcon } from '../../components/RenderFunctions';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import { caseTimelineTasksForAppeal } from '../../queue/selectors';
import moment from 'moment';

class DecisionDateTimeLine extends React.PureComponent {

  render = () => {
    const {
      appeal,
      taskList,
      timeline
    } = this.props;

    const showWithdrawalDate = () => {
      return appeal.withdrawalDate ? <div>
        <dt>{COPY.TASK_SNAPSHOT_TASK_WITHDRAWAL_DATE_LABEL}</dt>
        <dd>{moment(appeal.withdrawalDate).format('MM/DD/YYYY')}</dd></div> : null;
    };

    const showDecisionDate = () => {
      return appeal.decisionDate ? <div>
        <dd>{moment(appeal.decisionDate).format('MM/DD/YYYY')}</dd></div> : null;
    };

    return <React.Fragment>
      {timeline && <tr>
        <td className="taskContainerStyling taskTimeTimelineContainerStyling">
          <CaseDetailsDescriptionList>
            { appeal.decisionDate ? showDecisionDate() : showWithdrawalDate() }
          </CaseDetailsDescriptionList>
        </td>
        <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
          {appeal.withdrawalDate || appeal.decisionDate ?
            <span className="timelineLeftPaddingStyle"></span> : <span className="greyDotTimelineStyling"></span>}
          {appeal.withdrawn ? <CancelIcon /> : appeal.decisionDate ? <GreenCheckmark /> : <GrayDot /> }
          { (taskList.length > 0 || (appeal.isLegacyAppeal && appeal.form9Date) || (appeal.nodDate)) &&
          <div>{appeal.withdrawn || appeal.decisionDate ?
            <span className="grayLineStyling grayLineTimelineStyling">
            </span> : <span className="grayBvaPendingLineStyling"></span>}</div>}
        </td>
        <td className="taskContainerStyling taskInformationTimelineContainerStyling">
          {appeal.withdrawn ? COPY.CASE_TIMELINE_APPEAL_WITHDRAWN : appeal.decisionDate ?
            COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA : COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING } <br />
        </td>
      </tr>}
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId })
  };
};

export default connect(mapStateToProps)(DecisionDateTimeLine);


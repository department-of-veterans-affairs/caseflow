import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import COPY from '../../../COPY.json';
import { GrayDot, GreenCheckmark, CancelIcon } from '../../components/RenderFunctions';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import { caseTimelineTasksForAppeal } from '../../queue/selectors';
import moment from 'moment';

const greyDotTimelineStyling = css({ padding: '0px 0px 0px 5px' });
const timelineLeftPaddingStyle = css({ paddingLeft: '0px' });

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

    let timelineContainerText;
    let timeLineIcon;
    let grayLineIconStyling;

    if (appeal.withdrawn) {
      timelineContainerText = COPY.CASE_TIMELINE_APPEAL_WITHDRAWN;
      timeLineIcon = <CancelIcon />;
    } else if (appeal.decisionDate) {
      timelineContainerText = COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA;
      timeLineIcon = <GreenCheckmark />;
    } else {
      timelineContainerText = COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING;
      timeLineIcon = <GrayDot />;
      grayLineIconStyling = css({ top: '25px !important',
        left: '35.5%',
        marginLeft: 0 });
    }

    dateColumn = (appealCompletedDate = null) => {
      return <td className="taskContainerStyling taskTimeTimelineContainerStyling">
        <CaseDetailsDescriptionList>
          <div>
            <dd>{appealCompletedDate && moment(appealCompletedDate).format('MM/DD/YYYY')}</dd>
          </div>
        </CaseDetailsDescriptionList>
      </td>
    };

    iconColumn = () => {
      return <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer"
        {...(appeal.withdrawalDate || appeal.decisionDate ? timelineLeftPaddingStyle : greyDotTimelineStyling)}>
        {timeLineIcon}
        { (taskList.length > 0 || (appeal.isLegacyAppeal && appeal.form9Date) || (appeal.nodDate)) &&
        <div className="grayLineStyling grayLineTimelineStyling" {...grayLineIconStyling} />}
      </td>
    }

    descriptionColumn (timelineText) => {
      <td className="taskContainerStyling taskInformationTimelineContainerStyling">
        { timelineText } <br />
      </td>
    }

    withdrawalTimeline = () => {
      return <React.Fragment>
        { dateColumn(appeal.withdrawalDate) }
        { iconColumn() }
        { descriptionColumn(COPY.CASE_TIMELINE_APPEAL_WITHDRAWN) }
      </React.Fragment>;
    }

    completedTimeline = () => {
      return <React.Fragment>
        { dateColumn(appeal.decisionDate) }
        { iconColumn() }
        { descriptionColumn(COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA) }
      </React.Fragment>;
    }

    timelineTop = (date, icon, text) => {
      return <React.Fragment>
        { dateColumn(date) }
        { iconColumn(icon) }
        { descriptionColumn(text) }
      </React.Fragment>;
    }

    const appealPending = !(appeal.decisionDate || appeal.withdrawalDate)

    return <React.Fragment>
      { timeline }
      <tr>
        { appeal.withdrawalDate && timelineTop(appeal.withdrawalDate, cancelIcon, COPY.CASE_TIMELINE_APPEAL_WITHDRAWN) }
        { appeal.decisionDate && timelineTop(appeal.decisionDate, cancelIcon, COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA) }
        { appealPending && timelineTop(null, cancelIcon, COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING) }
      </tr>
    </React.Fragment>;

    // return <React.Fragment>
    //   {timeline && <tr>
    //     <td className="taskContainerStyling taskTimeTimelineContainerStyling">
    //       <CaseDetailsDescriptionList>
    //         { appeal.decisionDate ? showDecisionDate() : showWithdrawalDate() }
    //       </CaseDetailsDescriptionList>
    //     </td>
    //     <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer"
    //       {...(appeal.withdrawalDate || appeal.decisionDate ? timelineLeftPaddingStyle : greyDotTimelineStyling)}>
    //       {timeLineIcon}
    //       { (taskList.length > 0 || (appeal.isLegacyAppeal && appeal.form9Date) || (appeal.nodDate)) &&
    //       <div className="grayLineStyling grayLineTimelineStyling" {...grayLineIconStyling} />}
    //     </td>
    //     <td className="taskContainerStyling taskInformationTimelineContainerStyling">
    //       { timelineContainerText } <br />
    //     </td>
    //   </tr>}
    // </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId })
  };
};

export default connect(mapStateToProps)(DecisionDateTimeLine);

import React, { Fragment } from 'react';
import StatusMessage from '../../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import _ from 'lodash';

const getChecklistItems = (requestIssues, isInformalConferenceRequested)  => {
  const checklist = [];
  const [ratedIssues, nonRatedIssues] = _.partition(requestIssues, 'reference_id');

  if (ratedIssues.length > 0) {
    const ratedContentions = ratedIssues.map(ri => <p>Contention: {ri.description}</p>);
    checklist.push(
      <Fragment>
        <strong>A Higher-Level Review Rating EP is being established:</strong>
        {ratedContentions}
      </Fragment>
    );
  }

  if (nonRatedIssues.length > 0) {
    const nonRatedContentions = nonRatedIssues.map(nri => <p>Contention: {nri.description}</p>);
    checklist.push(
      <Fragment>
        <strong>A Higher-Level Review Nonrating EP is being established:</strong>
        {nonRatedContentions}
      </Fragment>
    );
  }

  if (isInformalConferenceRequested) {
    checklist.push('Informal Conference Tracked Item');
  }

  return checklist;
};

class Completed extends React.PureComponent {
  render() {
    const {
      veteran,
      endProductDescription,
      higherLevelReviewStatus,
      requestIssues,
      isInformalConferenceRequested
    } = this.props;

    switch (higherLevelReviewStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    const leadMessageList = [
      `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
        `${FORM_TYPES.HIGHER_LEVEL_REVIEW.name}` +
        ' has been processed. If you need to edit this, go to VBMS claim details and click the “Edit in Caseflow” button.',
      <strong>Edit the notice letter to reflect the status of requested issues.</strong>
    ];

    return <StatusMessage
      title="Intake completed"
      type="success"
      leadMessageList={leadMessageList}
      checklist={getChecklistItems(requestIssues, isInformalConferenceRequested)}
      wrapInAppSegment={false}
    />;
  }
}

export default connect(
  (state) => ({
    veteran: state.intake.veteran,
    endProductDescription: state.higherLevelReview.endProductDescription,
    higherLevelReviewStatus: getIntakeStatus(state),
    requestIssues: state.higherLevelReview.requestIssues,
    isInformalConferenceRequested: state.higherLevelReview.informalConference
  })
)(Completed);

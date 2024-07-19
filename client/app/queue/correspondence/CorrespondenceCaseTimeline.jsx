import React from 'react';
import PropTypes from 'prop-types';
import TaskRows from '../components/TaskRows.jsx';
import CorrespondenceTaskRows from './CorrespondenceTaskRows.jsx';
const CorrespondenceCaseTimeline = (props) => {
  // const tabs = useSelector((state) => loadCorrespondence(state, {  }));
  const debugData = [
    {
      // uniqueId: '3083',
      // isLegacy: false,
      type: 'IssuesUpdateTask',
      // appealType: 'LegacyAppeal',
      // addedByCssId: 15,
      // appealId: 13,
      // externalAppealId: '3619838',
      assignedOn: '2024-07-18T15:51:22.946-04:00',
      // closestRegionalOffice: null,
      createdAt: '2024-07-18T15:51:22.946-04:00',
      // closedAt: '2024-07-18T15:51:22.992-04:00',
      startedAt: null,
      assigneeName: 'Special Issue Edit Team',
      assignedTo: {
        cssId: 'null',
        name: 'Special Issue Edit Team',
        id: 74,
        isOrganization: true,
        type: 'SpecialIssueEditTeam'
      },
      assignedBy: {
        firstName: 'Deborah',
        lastName: 'Wise',
        cssId: 'BVADWISE',
        pgId: 18
      },
      completedBy: {
        cssId: 'BVADWISE'
      },
      cancelledBy: {
        cssId: null
      },
      cancelReason: null,
      convertedBy: {
        cssId: null
      },
      convertedOn: null,
      taskId: '3083',
      parentId: 3082,
      label: 'Issues Update Task',
      caseType: 'Post Remand',
      aod: false,
      previousTaskAssignedOn: null,
      placedOnHoldAt: null,
      status: 'completed',
      onHoldDuration: null,
      instructions: [
        [
          'Edited Issue',
          '',
          'Benefit Type: Compensation\n\r\nIssue: TDIU\n\r\nCode: 02 - Entitlement\n\r\nNote: Provident rerum dolor temporibus.\n\r\nDisposition: \n',
          'Special Issues: None',
          'Special Issues: MST, PACT'
        ]
      ],
      decisionPreparedBy: null,
      availableActions: [],
      timelineTitle: 'IssuesUpdateTask completed',
      hideFromQueueTableView: false,
      hideFromTaskSnapshot: false,
      hideFromCaseTimeline: false,
      availableHearingLocations: [],
      latestInformalHearingPresentationTask: {},
      canMoveOnDocketSwitch: false,
      timerEndsAt: null,
      unscheduledHearingNotes: {},
      ownedBy: 'Special Issue Edit Team',
      // daysSinceLastStatusChange: 10,
      // daysSinceBoardIntake: 10,
      id: '3083',
      claimant: {},
      appeal_receipt_date: 100,
    },
    {
      // uniqueId: '3083',
      // isLegacy: false,
      type: 'IssuesUpdateTask',
      // appealType: 'LegacyAppeal',
      // addedByCssId: 15,
      // appealId: 13,
      // externalAppealId: '3619838',
      assignedOn: '2024-07-18T15:51:22.946-04:00',
      // closestRegionalOffice: null,
      createdAt: '2024-07-18T15:51:22.946-04:00',
      // closedAt: '2024-07-18T15:51:22.992-04:00',
      startedAt: null,
      assigneeName: 'Special Issue Edit Team',
      assignedTo: {
        cssId: 'null',
        name: 'Special Issue Edit Team',
        id: 74,
        isOrganization: true,
        type: 'SpecialIssueEditTeam'
      },
      assignedBy: {
        firstName: 'Deborah',
        lastName: 'Wise',
        cssId: 'BVADWISE',
        pgId: 18
      },
      completedBy: {
        cssId: 'BVADWISE'
      },
      cancelledBy: {
        cssId: null
      },
      cancelReason: null,
      convertedBy: {
        cssId: null
      },
      convertedOn: null,
      taskId: '3083',
      parentId: 3082,
      label: 'Issues Update Task',
      caseType: 'Post Remand',
      aod: false,
      previousTaskAssignedOn: null,
      placedOnHoldAt: null,
      status: 'completed',
      onHoldDuration: null,
      instructions: [
        [
          'Edited Issue',
          '',
          'Benefit Type: Compensation\n\r\nIssue: TDIU\n\r\nCode: 02 - Entitlement\n\r\nNote: Provident rerum dolor temporibus.\n\r\nDisposition: \n',
          'Special Issues: None',
          'Special Issues: MST, PACT'
        ]
      ],
      decisionPreparedBy: null,
      availableActions: [],
      timelineTitle: 'IssuesUpdateTask completed',
      hideFromQueueTableView: true,
      hideFromTaskSnapshot: true,
      hideFromCaseTimeline: true,
      availableHearingLocations: [],
      latestInformalHearingPresentationTask: {},
      canMoveOnDocketSwitch: false,
      timerEndsAt: null,
      unscheduledHearingNotes: {},
      ownedBy: 'Special Issue Edit Team',
      // daysSinceLastStatusChange: 10,
      // daysSinceBoardIntake: 10,
      id: '3083',
      claimant: {},
      appeal_receipt_date: 100,
    }
  ];

  // console.log(props)

  return (
    <React.Fragment>
      <table id="case-timeline-table" summary="layout table">
        <tbody>
        <CorrespondenceTaskRows appeal={props.correspondence}
            taskList={debugData}
            editNodDateEnabled={true}
            timeline
            statusSplit
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

CorrespondenceCaseTimeline.propTypes = {
  loadCorrespondence: PropTypes.func,
  correspondence: PropTypes.object
};

export default CorrespondenceCaseTimeline;

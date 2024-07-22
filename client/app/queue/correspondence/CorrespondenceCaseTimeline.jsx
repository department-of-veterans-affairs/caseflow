import React from 'react';
import PropTypes from 'prop-types';
import TaskRows from '../components/TaskRows.jsx';
import CorrespondenceTaskRows from './CorrespondenceTaskRows.jsx';
const CorrespondenceCaseTimeline = (props) => {
  // const tabs = useSelector((state) => loadCorrespondence(state, {  }));

  const actions = [
    { value: 'changeTask', label: 'Change task type' },
    { value: 'changeTask', label: 'Assign to team' },
    { value: 'changeTask', label: 'Assign to person' },
    { value: 'changeTask', label: 'Mark task complete' },
    { value: 'changeTask', label: 'Return to Inbound Ops' },
    { value: 'changeTask', label: 'Cancel task' },
  ];

  const formatTaskData = () => {
    console.log(props.correspondence.tasksUnrelatedToAppeal);

    return (props.correspondence.tasksUnrelatedToAppeal.map((task) => {
      return {
        assignedOn: task.assigned_at,
        assignedTo: task.assigned_to,
        label: task.type,
        instructions: task.instructions,
        availableActions: actions,
      };
    }));
  };

  formatTaskData();

  const debugData = [
    {
      assignedOn: '2024-07-18T15:51:22.946-04:00',
      assignedBy: 'test',
      instructions: ['test2'],
      availableActions: actions,
      label: 'CHANGEME',
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
      assignedBy: 'test2 name',
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
          null, null, 'test'
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
            taskList={formatTaskData()}
            editNodDateEnabled
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

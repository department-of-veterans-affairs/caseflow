import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import TaskRows from '../../../../app/queue/components/TaskRows';

const reviewTranscriptTask = {
  uniqueId: '8115',
  isLegacy: false,
  type: 'ReviewTranscriptTask',
  appealType: 'Appeal',
  addedByCssId: null,
  appealId: 1880,
  externalAppealId: 'ba0ae03c-2331-4d79-ba1b-8c8089130979',
  assignedOn: '2024-08-05T10:57:27.269-04:00',
  closestRegionalOffice: null,
  createdAt: '2024-09-04T10:57:27.317-04:00',
  closedAt: '2024-09-04T10:57:27.315-04:00',
  startedAt: '2024-08-12T10:57:27.315-04:00',
  assigneeName: "Board of Veterans' Appeals",
  assignedTo: {
    cssId: null,
    name: "Board of Veterans' Appeals",
    id: 7,
    isOrganization: true,
    type: 'Bva'
  },
  assignedBy: {
    firstName: 'Lauren',
    lastName: 'Roth',
    cssId: 'CSSID1847365',
    pgId: 2579
  },
  completedBy: {
    cssId: '123'
  },
  cancelledBy: {
    cssId: null
  },
  cancelReason: null,
  convertedBy: {
    cssId: null
  },
  convertedOn: null,
  taskId: '8110',
  parentId: 8109,
  label: 'Schedule hearing',
  documentId: null,
  externalHearingId: '6a59e69b-9ecb-4332-a0fb-b07fa2ce214f',
  workProduct: null,
  caseType: 'Original',
  aod: false,
  previousTaskAssignedOn: null,
  placedOnHoldAt: null,
  status: 'completed',
  onHoldDuration: null,
  instructions: [
    'Schedule Veteran and/or appellant for Board hearing.'
  ],
  decisionPreparedBy: null,
  availableActions: [],
  timelineTitle: 'ReviewTranscriptTask completed',
  hideFromQueueTableView: false,
  hideFromTaskSnapshot: false,
  hideFromCaseTimeline: false,
  availableHearingLocations: [],
  latestInformalHearingPresentationTask: {},
  canMoveOnDocketSwitch: false,
  timerEndsAt: null,
  unscheduledHearingNotes: {},
  ownedBy: "Board of Veterans' Appeals",
  daysSinceLastStatusChange: 47,
  daysSinceBoardIntake: 47,
  id: '8115',
  claimant: {},
  appeal_receipt_date: '2024-06-18'
};

test('renders ReviewTranscriptTask details correctly', () => {

  render(<TaskRows taskList={[reviewTranscriptTask]} appeal={{}} />);

  // Check if assigned by and assignee names are rendered correctly
  expect(screen.getByText('L. Roth')).toBeInTheDocument();
  expect(screen.getByText('Board of Veterans\' Appeals')).toBeInTheDocument();

  // Check if task status is rendered
  expect(screen.getByText('Completed on')).toBeInTheDocument();

  // Check if the task instructions are rendered
  expect(screen.getByText('View task instructions')).toBeInTheDocument();
});

test('toggles task instructions visibility', () => {

  render(<TaskRows taskList={[reviewTranscriptTask]} appeal={{}} />);

  // Check if the instructions are initially hidden
  expect(screen.queryByText('Schedule Veteran and/or appellant for Board hearing.')).not.toBeInTheDocument();

  // Click the toggle button
  fireEvent.click(screen.getByText('View task instructions'));

  // Check if the instructions are now visible
  expect(screen.getByText('No errors found: Upload transcript to VBMS')).toBeInTheDocument();
  expect(screen.getByText('Schedule Veteran and/or appellant for Board hearing.')).toBeInTheDocument();
});

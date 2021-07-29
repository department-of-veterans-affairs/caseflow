const getAmaTaskTemplate = ({ id }) => ({
  uniqueId: id.toString(),
  isLegacy: false,
  type: 'RootTask',
  appealType: 'Appeal',
  addedByCssId: null,
  appealId: 1,
  externalAppealId: 'b83e027f-33f2-485b-9846-3f7e12f869d7',
  assignedOn: '2021-04-29T10:33:06.750-04:00',
  closestRegionalOffice: null,
  createdAt: '2021-04-29T10:33:06.750-04:00',
  closedAt: '2021-04-29T10:33:08.151-04:00',
  startedAt: null,
  assigneeName: "Board of Veterans' Appeals",
  assignedTo: {
    cssId: null,
    name: "Board of Veterans' Appeals",
    id: 5,
    isOrganization: true,
    type: 'Bva',
  },
  assignedBy: {
    firstName: '',
    lastName: '',
    cssId: null,
    pgId: null,
  },
  cancelledBy: {
    cssId: null,
  },
  convertedBy: {
    cssId: null,
  },
  convertedOn: null,
  taskId: id,
  parentId: null,
  label: 'Root Task',
  documentId: null,
  externalHearingId: null,
  workProduct: null,
  previousTaskAssignedOn: null,
  placedOnHoldAt: '2021-04-29T10:33:06.895-04:00',
  status: 'completed',
  onHoldDuration: null,
  instructions: [],
  decisionPreparedBy: null,
  availableActions: [
    {
      label: 'Create mail task',
      func: 'mail_assign_to_organization_data',
      value: 'modal/create_mail_task',
      data: {
        options: [
          {
            value: 'CavcCorrespondenceMailTask',
            label: 'CAVC Correspondence',
          },
          {
            value: 'ClearAndUnmistakeableErrorMailTask',
            label: 'CUE-related',
          },
          {
            value: 'AddressChangeMailTask',
            label: 'Change of address',
          },
          {
            value: 'CongressionalInterestMailTask',
            label: 'Congressional interest',
          },
          {
            value: 'ControlledCorrespondenceMailTask',
            label: 'Controlled correspondence',
          },
          {
            value: 'DeathCertificateMailTask',
            label: 'Death certificate',
          },
          {
            value: 'EvidenceOrArgumentMailTask',
            label: 'Evidence or argument',
          },
          {
            value: 'ExtensionRequestMailTask',
            label: 'Extension request',
          },
          {
            value: 'FoiaRequestMailTask',
            label: 'FOIA request',
          },
          {
            value: 'HearingRelatedMailTask',
            label: 'Hearing-related',
          },
          {
            value: 'ReconsiderationMotionMailTask',
            label: 'Motion for reconsideration',
          },
          {
            value: 'AodMotionMailTask',
            label: 'Motion to Advance on Docket',
          },
          {
            value: 'VacateMotionMailTask',
            label: 'Motion to vacate',
          },
          {
            value: 'OtherMotionMailTask',
            label: 'Other motion',
          },
          {
            value: 'PowerOfAttorneyRelatedMailTask',
            label: 'Power of attorney-related',
          },
          {
            value: 'PrivacyActRequestMailTask',
            label: 'Privacy act request',
          },
          {
            value: 'PrivacyComplaintMailTask',
            label: 'Privacy complaint',
          },
          {
            value: 'ReturnedUndeliverableCorrespondenceMailTask',
            label: 'Returned or undeliverable mail',
          },
          {
            value: 'StatusInquiryMailTask',
            label: 'Status inquiry',
          },
          {
            value: 'AppealWithdrawalMailTask',
            label: 'Withdrawal of appeal',
          },
        ],
      },
    },
  ],
  timelineTitle: 'RootTask completed',
  hideFromQueueTableView: false,
  hideFromTaskSnapshot: true,
  hideFromCaseTimeline: true,
  availableHearingLocations: [],
  latestInformalHearingPresentationTask: {},
  canMoveOnDocketSwitch: false,
});

const amaTaskWith = ({ id, ...rest }) => {
  return {
    ...getAmaTaskTemplate({ id }),
    ...rest,
  };
};

const RootTask = {
  type: 'RootTask',
  label: 'Root Task',
  hideFromCaseTimeline: true,
};

const DistributionTask = {
  type: 'DistributionTask',
  label: 'Distribution Task',
};

// the array index (idx) is zero-based
// for the id below, we just incremented by one so that we had more realistic (non-zero) IDs
export const getAmaTasks = (taskArray) => {
  const tasks = taskArray.map((attributes, idx) =>
    amaTaskWith({
      id: idx + 1,
      hideFromCaseTimeline: false,
      ...attributes,
    })
  );

  return tasks;
};

export const sampleTasksForEvidenceSubmissionDocket = () => {
  const taskTypes = [
    RootTask,
    {
      ...DistributionTask,
      parentId: 1,
    },
    {
      type: 'EvidenceSubmissionWindowTask',
      label: 'Evidence Submission Window Task',
      parentId: 2,
      timerEndsAt: '2021-05-30T10:33:08.151-04:00',
    },
    {
      type: 'JudgeAssignTask',
      label: 'Assign',
      parentId: 1,
      closedAt: '2021-04-28T10:33:08.151-04:00',
    },
    {
      type: 'JudgeDecisionReviewTask',
      label: 'Review',
      parentId: 1,
    },
    {
      type: 'AttorneyTask',
      label: 'Draft decision',
      parentId: 4,
    },
    {
      type: 'BvaDispatchTask',
      label: 'Board Dispatch',
      parentId: 1,
      assignedTo: {
        name: 'Board Dispatch',
        isOrganization: true,
      },
    },
    {
      type: 'BvaDispatchTask',
      label: 'Board Dispatch',
      parentId: 7,
      assignedTo: {
        isOrganization: false,
      },
    },
  ];

  return getAmaTasks(taskTypes);
};

// This is an improbable combination of tasks, used to demonstrate functionality
// in SubstituteAppellantTasksFormWithEverything.
export const myriadTasksForTaskForm = () => {
  const taskTypes = [
    RootTask,
    { DistributionTask },
    { type: 'EvidenceSubmissionWindowTask', label: 'Evidence Submission Window Task' },
    { type: 'JudgeAssignTask', label: 'Assign' },
    { type: 'JudgeDecisionReviewTask', label: 'Review' },
    { type: 'AttorneyTask', label: 'Draft decision' },
    { type: 'BvaDispatchTask', label: 'Board Dispatch' },
    { type: 'ScheduleHearingTask', label: 'Schedule hearing' },
    { type: 'AssignHearingDispositionTask', label: 'Assign hearing disposition' },
    { type: 'ChangeHearingDispositionTask', label: 'Change hearing disposition' },
    { type: 'TranscriptionTask', label: 'Transcription task' },
  ];

  return getAmaTasks(taskTypes);
};

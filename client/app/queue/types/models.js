// @flow

export type User = {
  id: number,
  station_id: string,
  css_id: string,
  full_name: string,
  email: ?string,
  roles: Array<string>,
  selected_regional_office: ?string,
  display_name: string
};

export type Judges = { [string]: User };

export type Address = {
  address_line_1: string,
  address_line_2: string,
  address_line_3: ?string,
  city: string,
  state: string,
  zip: string,
  country: string
};

export type VeteranInfo = {
  full_name: ?string,
  gender: ?string,
  date_of_birth: Date,
  regional_office: Object,
  address: ?Address
};

export type Issue = {
  levels: Array<string>,
  program?: string,
  type: string,
  codes: Array<string>,
  disposition: string,
  close_date: Date,
  note: string,
  id: Number,
  vacols_sequence_id?: Number,
  labels: Array<string>,
  readjudication: Boolean,
  remand_reasons: Array<Object>,
  benefit_type?: string,
  diagnostic_code?: string,
  description?: string
};

export type Issues = Array<Issue>;

export type Task = {
  uniqueId: string,
  isLegacy: boolean,
  type: ?string,
  label: string,
  appealId: number,
  appealType: string,
  externalAppealId: string,
  assignedOn: string,
  closedAt: ?string,
  dueOn: ?string,
  assignedTo: {
    cssId: ?string,
    type: string,
    id: number,
    isOrganization: boolean,
    name: ?string
  },
  assignedBy: {
    firstName: string,
    lastName: string,
    cssId: string,
    pgId: number,
  },
  addedByName?: string,
  addedByCssId: ?string,
  taskId: string,
  documentId: ?string,
  workProduct: ?string,
  status?: string,
  placedOnHoldAt?: ?string,
  onHoldDuration?: ?number,
  previousTaskAssignedOn: ?string,
  instructions?: Array<string>,
  parentId?: number,
  decisionPreparedBy: ?{
    firstName: string,
    lastName: string,
  },
  availableActions: Array<{ label?: string, value: string, data: ?Object }>,
  hideFromQueueTableView: boolean,
  hideFromCaseTimeline: boolean,
  hideFromTaskSnapshot: boolean,
  closestRegionalOffice: string
};

export type Tasks = { [string]: Task };

export type PowerOfAttorney = {
  representative_type: ?string,
  representative_name: ?string,
  representative_address: ?Address
}

export type Hearing = {
  heldBy: string,
  viewedByJudge: boolean,
  date: string,
  type: string,
  externalId: string,
  disposition: string
};

export type AppealDetail = {
  issues: Array<Object>,
  decisionIssues: Array<Object>,
  hearings: Array<Hearing>,
  completedHearingOnPreviousAppeal: boolean,
  appellantFullName: string,
  appellantAddress: Address,
  appellantRelationship: string,
  locationCode: ?string,
  externalId: string,
  status: string,
  decisionDate: string,
  events: {
    nodReceiptDate: ?string,
    form9Date: ?string,
  },
  certificationDate: ?string,
  powerOfAttorney: ?PowerOfAttorney,
  caseflowVeteranId: ?string,
  tasks: ?Array<Task>,
  veteranAvailableHearingLocations: ?Array<Object>,
  veteranClosestRegionalOffice: ?string
};

export type AppealDetails = { [string]: AppealDetail };

export type BasicAppeal = {
  id: number,
  type: string,
  externalId: string,
  docketName: ?string,
  isLegacyAppeal: boolean,
  caseType: string,
  isAdvancedOnDocket: boolean,
  docketNumber: string,
  assignedAttorney: ?User,
  assignedJudge: ?User,
  veteranFullName: string,
  veteranFileNumber: string,
  isPaperCase: ?boolean,
  tasks?: Array<Task>,
  issueCount: number,
  sanitizedHearingRequestType?: string,
  regionalOffice?: ?{
    key: ?string,
    city: ?string,
    state: ?string
  }
};

export type BasicAppeals = { [string]: BasicAppeal };

export type Appeal = AppealDetail & BasicAppeal;

export type Appeals = { [string]: Appeal };

export type ClaimReview = {
  caseflowVeteranId: string,
  claimId: number,
  claimantNames: ?Array<string>,
  endProductStatuses: ?Array<Object>,
  reviewType: string,
  veteranFileNumber: string,
  veteranFullName: string
};

export type ClaimReviews = { [string]: ClaimReview };

export type Attorneys = {
  data?: Array<User>,
  error?: Object
};

export type TaskWithAppeal = Task & {
  appeal: Appeal
};

export type Distribution = {|
  id: number,
  status: string,
  created_at: string,
  updated_at: string,
  distributed_cases_count: number
|};

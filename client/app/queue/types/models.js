// @flow

export type User = {
  id: number,
  station_id: string,
  css_id: string,
  full_name: string,
  email: ?string,
  roles: Array<String>,
  selected_regional_office: ?string,
  display_name: string,
  judge_css_id: ?string
};

export type Judges = { [string]: User };

export type AppellantAddress = {
  address_line_1: string,
  address_line_2: string,
  city: string,
  state: string,
  zip: string,
  country: string
};

export type Issue = {
  levels: Array<string>,
  program: string,
  type: string,
  codes: Array<string>,
  disposition: string,
  close_date: Date,
  note: string,
  vacols_sequence_id: Number,
  labels: Array<string>,
  readjudication: Boolean,
  remand_reasons: Array<Object>
};

export type Issues = Array<Issue>;

export type LegacyTask = {
  type: string,
  title: string,
  appealId: string,
  appealType: string,
  externalAppealId: string,
  assignedOn: string,
  dueOn: string,
  userId: string,
  assignedToPgId: string,
  addedByName: string,
  addedByCssId: string,
  taskId: string,
  taskType: string,
  documentId: string,
  assignedByFirstName: string,
  assignedByLastName: string,
  workProduct: string,
  previousTaskAssignedOn: string
};

export type LegacyTasks = { [string]: LegacyTask };

export type AmaTask = {
  id: string,
  type: string,
  attributes: {
    action: string,
    aod: boolean,
    appeal_id: string,
    assigned_at: string,
    assigned_by: User,
    assigned_to: User,
    case_type: string,
    completed_at: ?string,
    docket_name: ?string,
    docket_number: string,
    external_id: string,
    instructions: ?string,
    placed_on_hold_at: ?string,
    started_at: ?string,
    status: string,
    type: string,
    veteran_file_number: string,
    veteran_name: ?string
  }
};

export type AmaTasks = { [string]: AmaTask };

export type LegacyAppeal = {
  id: string,
  attributes: {
    is_legacy_appeal: boolean,
    issues: Array<Object>,
    hearings: Array<Object>,
    appellant_full_name: string,
    appellant_address: AppellantAddress,
    appellant_relationship: string,
    location_code: string,
    veteran_full_name: string,
    veteran_date_of_birth: string,
    veteran_gender: string,
    vbms_id: string,
    external_id: string,
    type: string,
    aod: boolean,
    docket_number: string,
    status: string,
    decision_date: string,
    certification_date: string,
    paper_case: boolean,
    power_of_attorney: string,
    regional_office: Object,
    caseflow_veteran_id: ?string
  },
  tasks: ?Array<LegacyTask>
};

export type BasicAppeal = {
  id: string,
  type: string,
  externalId: string,
  docketName: string,
  caseType: string,
  isAdvancedOnDocket: Boolean,
  issues: Array<Object>,
  docketNumber: string,
  veteranFullName: string,
  veteranFileNumber: string,
  isPaperCase: Boolean,
  tasks: ?Array<LegacyTask>
};

export type BasicAppeals = { [string]: BasicAppeal };

export type Appeal = {
  id: string,
  attributes: {
    is_legacy_appeal: Boolean,
    issues: Array<Object>,
    hearings: Array<Object>,
    appellant_full_name: string,
    appellant_address: AppellantAddress,
    appellant_relationship: string,
    veteran_full_name: string,
    veteran_date_of_birth: string,
    veteran_gender: string,
    vbms_id: string,
    external_id: string,
    type: string,
    aod: Boolean,
    docket_number: string,
    status: string,
    decision_date: string,
    paper_case: Boolean,
    power_of_attorney: string,
    caseflow_veteran_id: ?string
  }
};

export type LegacyAppeals = { [string]: LegacyAppeal };

export type Attorneys = {
  data?: Array<User>,
  error?: Object
};

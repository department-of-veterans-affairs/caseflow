// @flow

export type User = {
  id: number,
  station_id: string,
  css_id: string,
  full_name: string,
  email: ?string,
  roles: Array<String>,
  selected_regional_office: ?string,
  display_name: string
};

export type DeprecatedTask = {
  id: string
};

export type AppellantAddress = {
  address_line_1: string,
  address_line_2: string,
  city: string,
  state: string,
  zip: string,
  country: string
};

export type LegacyAppeal = {
  id: string,
  attributes: {
    is_legacy_appeal: Boolean,
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
    vacols_id: string,
    type: string,
    aod: Boolean,
    docket_number: string,
    status: string,
    decision_date: string,
    certification_date: string,
    paper_case: Boolean,
    power_of_attorney: string,
    regional_office: Object,
    caseflow_veteran_id: ?string
  }
};

export type LegacyAppeals = { [string]: LegacyAppeal };

export type Task = {
  id: string,
  appealId: string,
  attributes: {
    added_by_css_id: string,
    added_by_name: string,
    appeal_id: string,
    assigned_by_first_name: string,
    assigned_by_last_name: string,
    assigned_on: string,
    docket_date: string,
    docket_name: string,
    document_id: string,
    due_on: string,
    task_id: string,
    task_type: string,
    user_id: string,
    work_product: string
  }
};

export type Tasks = { [string]: Task };

export type Attorneys = {
  data?: Array<User>,
  error?: Object
};

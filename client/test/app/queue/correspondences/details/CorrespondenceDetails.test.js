import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import { correspondenceDetailsData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import thunk from 'redux-thunk';
import moment from 'moment';
import { prepareAppealForSearchStore, sortCaseTimelineEvents } from 'app/queue/utils';
import { MemoryRouter, Route } from 'react-router-dom';
import { within } from '@testing-library/dom';
import { tasksUnrelatedToAnAppeal } from 'test/data/queue/taskActionModals/taskActionModalData';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

jest.mock('app/queue/utils', () => ({
  prepareAppealForSearchStore: jest.fn(),
  sortCaseTimelineEvents: jest.fn()
}));

jest.mock('app/queue/CaseListTable', () => ({ appeals }) => (
  <div className="case-list-table">
    <table>
      <thead>
        <tr>
          <th>Docket Number</th>
          <th>Appellant Name</th>
          <th>Appeal Status</th>
          <th>Appeal Type</th>
          <th>Number of Issues</th>
          <th>Decision Date</th>
          <th>Appeal Location</th>
        </tr>
      </thead>
      <tbody>
        {appeals.map((appeal, index) => (
          <tr key={index}>
            <td>{appeal.docketNumber}</td>
            <td>{appeal.appellant_full_name}</td>
            <td>{appeal.status}</td>
            <td>{appeal.appealType}</td>
            <td>{appeal.issueCount}</td>
            <td>{appeal.decisionDate}</td>
            <td>{appeal.location}</td>
          </tr>
        ))}
      </tbody>
    </table>
  </div>
));

jest.mock('app/util/ApiUtil', () => ({
  post: jest.fn(),
}));

let initialState = {
  correspondence: correspondenceDetailsData
};

const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

let props = {
  organizations: ['Inbound Ops Team'],
  isInboundOpsUser: true,
  updateCorrespondenceRelations: jest.fn(),
  correspondence: {
    uuid: '123',
    veteranFullName: 'John Doe',
    veteranFileNumber: '123456789',
    correspondenceType: 'Abeyance',
    nod: false,
    notes: 'Note Test',
    mailTasks: ['Task 1', 'Task 2'],
    all_correspondences: Array.from({ length: 30 }, (_, i) => ({ uuid: `uuid${i}`,
      vaDateOfReceipt: '2024-08-06T00:00:00Z',
      notes: `Note ${i}`,
      status: `Status ${i}` })),
    prior_mail: [
      { id: 1, vaDateOfReceipt: '2023-08-20T00:00:00Z' },
      { id: 2, vaDateOfReceipt: '2023-08-19T00:00:00Z' }
    ],
    relatedCorrespondenceIds: [2],
    tasksUnrelatedToAppeal: tasksUnrelatedToAnAppeal,
    correspondenceAppeals: [
      {
        id: 50,
        correspondencesAppealsTasks: [],
        docketNumber: '240714-252',
        veteranName: {
          id: 88,
          bgs_last_synced_at: null,
          closest_regional_office: null,
          created_at: '2024-07-15T16:47:17.658-04:00',
          date_of_death: null,
          date_of_death_reported_at: null,
          file_number: '550000017',
          first_name: 'John',
          last_name: 'Doe',
          middle_name: null,
          name_suffix: '88',
          participant_id: '650000017',
          ssn: '252858736',
          updated_at: '2024-07-15T16:47:17.658-04:00'
        },
        streamType: 'original',
        appealUuid: 'b36f1011-a34b-413b-a2b9-90fe0d8b2927',
        appealType: 'evidence_submission',
        numberOfIssues: 2,
        taskAddedData: [],
        status: 'Pending',
        assignedTo: null,
        correspondence: {
          id: 50,
          appeal_id: 252,
          correspondence_id: 322,
          created_at: '2024-08-14T10:53:47.213-04:00',
          updated_at: '2024-08-14T10:53:47.213-04:00'
        }
      },
      {
        id: 51,
        correspondencesAppealsTasks: [
          {
            id: 27,
            correspondence_appeal_id: 51,
            task_id: 3158,
            created_at: '2024-08-14T10:53:47.616-04:00',
            updated_at: '2024-08-14T10:53:47.616-04:00'
          }
        ],
        docketNumber: '240714-253',
        veteranName: {
          id: 88,
          bgs_last_synced_at: null,
          closest_regional_office: null,
          created_at: '2024-07-15T16:47:17.658-04:00',
          date_of_death: null,
          date_of_death_reported_at: null,
          file_number: '550000017',
          first_name: 'John',
          last_name: 'Doe',
          middle_name: null,
          name_suffix: '88',
          participant_id: '650000017',
          ssn: '252858736',
          updated_at: '2024-07-15T16:47:17.658-04:00'
        },
        streamType: 'original',
        appealUuid: 'a9b2523e-880d-4ef4-9f12-eae9d593631d',
        appealType: 'evidence_submission',
        numberOfIssues: 2,
        taskAddedData: [
          {
            assigned_at: '2024-08-14T10:53:47.560-04:00',
            assigned_to: 'Hearing Admin',
            assigned_to_type: 'Organization',
            instructions: [
              'COA'
            ],
            type: 'Change of address'
          }
        ],
        status: 'Pending',
        assignedTo: {
          id: 39,
          accepts_priority_pushed_cases: null,
          ama_only_push: false,
          ama_only_request: false,
          created_at: '2024-07-15T16:46:00.263-04:00',
          exclude_appeals_from_affinity: false,
          name: 'Hearing Admin',
          participant_id: null,
          role: null,
          status: 'active',
          status_updated_at: null,
          updated_at: '2024-07-15T16:46:00.263-04:00',
          url: 'hearing-admin'
        },
        correspondence: {
          id: 51,
          appeal_id: 253,
          correspondence_id: 322,
          created_at: '2024-08-14T10:53:47.217-04:00',
          updated_at: '2024-08-14T10:53:47.217-04:00'
        }
      },
      {
        id: 52,
        correspondencesAppealsTasks: [
          {
            id: 1,
            correspondence_appeal_id: 52,
            task_id: 3160,
            created_at: '2024-08-14T10:53:47.678-04:00',
            updated_at: '2024-08-14T10:53:47.678-04:00'
          },
          {
            id: 29,
            correspondence_appeal_id: 52,
            task_id: 3162,
            created_at: '2024-08-14T10:53:47.733-04:00',
            updated_at: '2024-08-14T10:53:47.733-04:00'
          }
        ],
        docketNumber: '240714-254',
        veteranName: {
          id: 88,
          bgs_last_synced_at: null,
          closest_regional_office: null,
          created_at: '2024-07-15T16:47:17.658-04:00',
          date_of_death: null,
          date_of_death_reported_at: null,
          file_number: '550000017',
          first_name: 'John',
          last_name: 'Doe',
          middle_name: null,
          name_suffix: '88',
          participant_id: '650000017',
          ssn: '252858736',
          updated_at: '2024-07-15T16:47:17.658-04:00'
        },
        streamType: 'original',
        appealUuid: '7bd8281d-3b6e-442f-8e44-21b033f7049e',
        appealType: 'evidence_submission',
        numberOfIssues: 2,
        taskAddedData: [
          {
            assigned_at: '2024-08-14T10:53:47.656-04:00',
            assigned_to: 'VLJ Support Staff',
            assigned_to_type: 'Organization',
            instructions: [
              'DC'
            ],
            type: 'Death certificate'
          },
          {
            assigned_at: '2024-08-14T10:53:47.716-04:00',
            assigned_to: 'Litigation Support',
            assigned_to_type: 'Organization',
            instructions: [
              'cong int'
            ],
            type: 'Congressional interest'
          }
        ],
        status: 'Pending',
        assignedTo: {
          id: 8,
          accepts_priority_pushed_cases: null,
          ama_only_push: false,
          ama_only_request: false,
          created_at: '2024-07-15T16:45:56.066-04:00',
          exclude_appeals_from_affinity: false,
          name: 'VLJ Support Staff',
          participant_id: null,
          role: null,
          status: 'active',
          status_updated_at: null,
          updated_at: '2024-07-15T16:45:56.066-04:00',
          url: 'vlj-support'
        },
        correspondence: {
          id: 52,
          appeal_id: 254,
          correspondence_id: 322,
          created_at: '2024-08-14T10:53:47.221-04:00',
          updated_at: '2024-08-14T10:53:47.221-04:00'
        }
      }
    ],

    appeals_information:
      [
        {
          id: 1,
          type: 'Correspondence',
          attributes: {
            assigned_to_location: 'Mail',
            appellant_full_name: 'John Doe',
            type: 'Original',
            docket_number: '123-456'
          }
        }
      ],
    claim_reviews: []
  }
};

describe('CorrespondenceDetails', () => {

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    sortCaseTimelineEvents.mockReturnValue(
      tasksUnrelatedToAnAppeal
    );

    render(
      <Provider store={store}>
        <MemoryRouter>
          <Route>
            <CorrespondenceDetails {...props} />
          </Route>
        </MemoryRouter>
      </Provider>
    );
  });

  it('toggles view all correspondence', () => {
    const viewAllButton = screen.getByText('View all correspondence');

    fireEvent.click(viewAllButton);
    expect(screen.getByText('Hide all correspondence')).toBeInTheDocument();
  });

  it('renders the component', () => {
    const userNameCount = screen.getAllByText('John Doe').length;

    expect(userNameCount).toBeGreaterThan(0);
    const packageDetailsTab = screen.getByText('Package Details');
    const existingAppealButton = document.getElementsByClassName('plus-symbol')[0];
    // const responseLettersTab = screen.getByText('Response Letters');
    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    expect(screen.getByText('Veteran ID:')).toBeInTheDocument();
    expect(screen.getByText('Correspondence and Appeal Tasks')).toBeInTheDocument();
    expect(screen.getByText('Package Details')).toBeInTheDocument();
    expect(screen.getByText('Response Letters')).toBeInTheDocument();
    expect(screen.getByText('Associated Prior Mail')).toBeInTheDocument();
    expect(screen.getByText('View all correspondence')).toBeInTheDocument();
    expect(screen.getByText('Tasks not related to an appeal')).toBeInTheDocument();
    expect(screen.getByText('Completed Mail Tasks')).toBeInTheDocument();
    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();

    let collapsibleButtons = document.getElementsByClassName('plus-symbol');

    expect(collapsibleButtons.length).toBe(2);
    fireEvent.click(collapsibleButtons[0]);

    expect(document.getElementsByClassName('plus-symbol').length).toBe(1);
    // Existing Appeals Table and Columns
    fireEvent.click(existingAppealButton);
    expect(screen.getByText('Existing appeals')).toBeInTheDocument();
    expect(screen.getByText('Appellant Name')).toBeInTheDocument();
    expect(screen.getByText('Appeal Status')).toBeInTheDocument();
    expect(screen.getByText('Appeal Type')).toBeInTheDocument();
    expect(screen.getByText('Number of Issues')).toBeInTheDocument();
    expect(screen.getByText('Decision Date')).toBeInTheDocument();
    expect(screen.getByText('Appeal Location')).toBeInTheDocument();
    expect(screen.getByText('View veteran documents')).toBeInTheDocument();

    collapsibleButtons = document.getElementsByClassName('plus-symbol');
    fireEvent.click(collapsibleButtons[0]);

    expect(document.getElementsByClassName('plus-symbol').length).toBe(0);

    // Appeals related
    const existingAppeals = screen.getAllByText('Tasks added to appeal').length;

    expect(existingAppeals).toBe(3);
    expect(screen.getByText('240714-253')).toBeInTheDocument();
    expect(screen.getByText('240714-254')).toBeInTheDocument();
    expect(screen.getByText('VLJ Support Staff')).toBeInTheDocument();
    expect(screen.getByText('Hearing Admin')).toBeInTheDocument();

    // Appeals related
    const tasksAddedTextCount = screen.getAllByText('Tasks added to appeal').length;

    expect(tasksAddedTextCount).toBe(3);
    expect(screen.getByText('240714-253')).toBeInTheDocument();
    expect(screen.getByText('240714-254')).toBeInTheDocument();
    expect(screen.getByText('VLJ Support Staff')).toBeInTheDocument();
    expect(screen.getByText('Hearing Admin')).toBeInTheDocument();

    // Clicks on the Package Details Tab and tests its expectations
    fireEvent.click(packageDetailsTab);
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText(props.correspondence.veteranFullName)).toBeInTheDocument();
    expect(screen.getByText('Correspondence Type')).toBeInTheDocument();
    expect(screen.getByText(props.correspondence.correspondenceType)).toBeInTheDocument();
    expect(screen.getByText('Package Document Type')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();
    expect(screen.getByText('VA DOR')).toBeInTheDocument();
    expect(screen.getByText(moment(props.correspondence.vaDateOfReceipt).format('MM/DD/YYYY'))).toBeInTheDocument();
    expect(screen.getByText('Notes')).toBeInTheDocument();
    expect(screen.getByText(props.correspondence.notes)).toBeInTheDocument();

    fireEvent.click(associatedPriorMailTab);
    expect(screen.getByText('Please select prior mail to link to this correspondence')).toBeInTheDocument();
    const priorDate = new Date(props.correspondence.prior_mail[0].vaDateOfReceipt);

    expect(screen.getByText(priorDate.toLocaleDateString('en-US'))).toBeInTheDocument();
  });

  it('validates the options of the actions dropdown based on the task type', () => {
    const table = document.querySelector('#case-timeline-table');

    expect(table).toBeInTheDocument();

    const tasksUnrelatedToAppeal = props.correspondence.tasksUnrelatedToAppeal;

    tasksUnrelatedToAppeal.forEach((task) => {
      const label = task.label;
      const labelElement = screen.getAllByText(label, { selector: 'dd' })[0];
      const tableRow = labelElement.closest('tr');

      expect(tableRow).toBeInTheDocument();

      const dropdown = within(tableRow).getByRole('combobox');

      expect(dropdown).toBeInTheDocument();
      fireEvent.mouseDown(dropdown);

      // Find the listbox which contains the dropdown options
      const listbox = screen.getByRole('listbox', { name: /available-actions-listbox/i });

      // Ensure the listbox is present in the DOM
      expect(listbox).toBeInTheDocument();
      const options = within(listbox).getAllByRole('option');
      const optionLabels = options.map((option) => option.textContent.trim());

      expect(options).toHaveLength(task.availableActions.length);
      expect(optionLabels.sort()).toEqual(task.availableActions.map((action) => action.label).sort());
    });
  });

  it('validates save changes button', () => {

    let saveChangesButton = screen.getAllByText('Save changes')[0];

    expect(saveChangesButton).toBeInTheDocument();
    expect(saveChangesButton).toBeDisabled();
  });

  it('onPriorMailCheckboxChange selects/deselects prior mail and enables/disables the submit button', () => {

    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    fireEvent.click(associatedPriorMailTab);
    // Check the checkbox for the first prior mail item
    const checkbox = screen.getByRole('checkbox', { name: '1' });

    fireEvent.click(checkbox);

    // Check that the checkbox is checked and the submit button is enabled
    expect(checkbox).toBeChecked();
    expect(screen.getByText('Save changes')).not.toBeDisabled();

    // Uncheck the checkbox
    fireEvent.click(checkbox);

    // Check that the checkbox is unchecked and the submit button is disabled
    expect(checkbox).not.toBeChecked();
    expect(screen.getByText('Save changes')).toBeDisabled();
  });

  it('saveChanges sends API request and updates correspondence relations', async () => {
    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    fireEvent.click(associatedPriorMailTab);
    const checkbox = screen.getByRole('checkbox', { name: '1' });

    fireEvent.click(checkbox);

    // Mock API call
    const apiResponse = Promise.resolve();

    ApiUtil.post.mockReturnValueOnce(apiResponse);

    // Click the Save button
    fireEvent.click(screen.getByText('Save changes'));

    // Check if API call was made
    expect(ApiUtil.post).toHaveBeenCalledWith(
        `/queue/correspondence/${props.correspondence.uuid}/create_correspondence_relations`,
        { data: { priorMailIds: [1] } }
    );
  });
});

describe('Correspondence details without beforeEach', () => {

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    sortCaseTimelineEvents.mockReturnValue(
      tasksUnrelatedToAnAppeal
    );
    props.isInboundOpsUser = false;

    render(
      <Provider store={store}>
        <MemoryRouter>
          <Route>
            <CorrespondenceDetails {...props} />
          </Route>
        </MemoryRouter>
      </Provider>
    );
  });

  it('validates that save changes button is not present', () => {
    expect(screen.queryByText('Save changes')).not.toBeInTheDocument();
  });
});

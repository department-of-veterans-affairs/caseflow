/* eslint-disable max-lines */
import React from 'react';
import { render, waitFor, screen, cleanup } from '@testing-library/react';
import { TranscriptionFileDispatchTable } from '../../../../app/hearings/components/TranscriptionFileDispatchTable';
import TRANSCRIPTION_FILE_DISPATCH_CONFIG from '../../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import {
  unassignedColumns,
  assignedColumns,
  completedColumns,
  allColumns
} from '../../../../app/hearings/components/TranscriptionFileDispatchTabs';
import ApiUtil from '../../../../app/util/ApiUtil';
import { when } from 'jest-when';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { MemoryRouter as Router } from 'react-router-dom';

const mockTranscriptionFiles = [
  {
    id: 40,
    externalAppealId: 'b5eba21a-9baf-41a3-ac1c-08470c2b79c4',
    docketNumber: '200103-61110',
    caseDetails: 'Danial Reynolds (000543695)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '11/02/2020',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 39,
    externalAppealId: '12bb84ff-65fb-4422-bee4-fe7553fdf5c3',
    docketNumber: '190227-4821',
    caseDetails: 'Craig Wintheiser (000562812)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '08/27/2020',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 38,
    externalAppealId: '12bb84ff-65fb-4422-bee4-fe7553fdf5c3',
    docketNumber: '190227-4821',
    caseDetails: 'Craig Wintheiser (000562812)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '04/30/2020',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 37,
    externalAppealId: '12bb84ff-65fb-4422-bee4-fe7553fdf5c3',
    docketNumber: '190227-4821',
    caseDetails: 'Craig Wintheiser (000562812)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '01/13/2020',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 36,
    externalAppealId: '12bb84ff-65fb-4422-bee4-fe7553fdf5c3',
    docketNumber: '190227-4821',
    caseDetails: 'Craig Wintheiser (000562812)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '10/24/2019',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 35,
    externalAppealId: '9c14a2fd-348e-44d0-9465-5c3c6303b52d',
    docketNumber: '180910-667',
    caseDetails: 'Bud Hessel (000654829)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '04/04/2019',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 34,
    externalAppealId: '3ad0bcc7-613f-4fed-8088-024c93b2cb86',
    docketNumber: '230828-1803',
    caseDetails: 'Vernon Weimann (300000588)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '07/01/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 33,
    externalAppealId: '572480c5-f621-4038-84ae-fe96c8012f80',
    docketNumber: '230829-1801',
    caseDetails: 'Kirby Howe (300000587)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '07/01/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 32,
    externalAppealId: 'fbad9355-9bef-4957-92a3-f88e467aad66',
    docketNumber: '230830-1799',
    caseDetails: 'Glendora Parisian (300000583)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '06/18/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 31,
    externalAppealId: '6ec0df25-a7da-4a3d-8633-4120565ec8a6',
    docketNumber: '230831-1797',
    caseDetails: 'Buford Wunsch (300000582)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '06/18/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 30,
    externalAppealId: 'fca24f0c-30b8-4a41-b077-d0d140d6b266',
    docketNumber: '230901-1795',
    caseDetails: 'Renae Hansen (300000581)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '06/18/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 29,
    externalAppealId: '7ba4da54-6ed8-49c5-b79d-884539742990',
    docketNumber: '230902-1793',
    caseDetails: 'Donovan Doyle (300000578)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '07/01/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 28,
    externalAppealId: 'eeb095a4-3e43-4c4e-9f17-4cfd0d2af751',
    docketNumber: '230903-1791',
    caseDetails: 'Darrin Heathcote (300000577)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '07/01/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 27,
    externalAppealId: '040e56c6-5834-447e-b6d5-0f9a1d2007d3',
    docketNumber: '230904-1789',
    caseDetails: 'Timothy Spencer (300000573)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '06/18/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
  {
    id: 26,
    externalAppealId: '7b3f97c3-af0c-4b6c-9ac1-566382a66565',
    docketNumber: '230905-1787',
    caseDetails: 'Evia Gerhold (300000572)',
    isAdvancedOnDocket: false,
    caseType: 'Original',
    hearingDate: '06/18/2024',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
  },
];

const mockCompletedTranscriptionFiles = [
  {
    id: 40,
    externalAppealId: 'b5eba21a-9baf-41a3-ac1c-08470c2b79c4',
    docketNumber: '200103-61110',
    caseDetails: 'Danial Reynolds (000543695)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '11/02/2020',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
    returnDate: '01/02/2021',
    expectedReturnDate: '12/15/2020',
    contractor: 'Genesis Government Solutions, Inc.',
    workOrder: 'BVAXXXXXX',
    status: 'Completed',
  },
  {
    id: 39,
    externalAppealId: '12bb84ff-65fb-4422-bee4-fe7553fdf5c3',
    docketNumber: '190227-4821',
    caseDetails: 'Craig Wintheiser (000562812)',
    isAdvancedOnDocket: true,
    caseType: 'Original',
    hearingDate: '08/27/2020',
    hearingType: 'Hearing',
    fileStatus: 'Successful upload (AWS)',
    returnDate: '10/10/2020',
    uploadDate: '10/01/2020',
    contractor: 'Jamison Professional Services',
    workOrder: 'BVAXXXXXX',
    status: 'Completed-Overdue',
  }
];

const mockCompletedTranscriptionFilesResponse = {
  body: {
    task_page_count: 1,
    tasks: {
      data: mockCompletedTranscriptionFiles,
    },
    tasks_per_page: 15,
    total_task_count: 2,
  },
};

const mockAllTranscriptionFilesResponse = {
  body: {
    task_page_count: 1,
    tasks: {
      data: mockCompletedTranscriptionFiles,
    },
    tasks_per_page: 15,
    total_task_count: 2,
  },
};


const mockTranscriptionFilesResponse = {
  body: {
    task_page_count: 3,
    tasks: {
      data: mockTranscriptionFiles,
    },
    tasks_per_page: 15,
    total_task_count: 40,
  },
};

const mockLockedResponse = {
  body: [
    {
      id: 40,
      status: 'selected',
      message: '',
    },
    {
      id: 39,
      status: 'locked',
      message: 'Locked by QATTY2',
    },
  ],
};

const selectAllData = {
  data: {
    file_ids: [40, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26],
    status: true,
  },
};

const mockSelectAllResponse = {
  body: [
    {
      id: 40,
      status: 'selected',
      message: '',
    },
    {
      id: 38,
      status: 'selected',
      message: '',
    },
    {
      id: 37,
      status: 'selected',
      message: '',
    },
  ],
};

const mockClickedResponse = {
  body: [
    {
      id: 40,
      status: 'selected',
      message: '',
    },
    {
      id: 39,
      status: 'locked',
      message: 'Locked by QATTY2',
    },
    {
      id: 38,
      status: 'selected',
      message: '',
    },
  ],
};

const constClickData = { data: { file_ids: [37], status: true } };

const mockTranscriptionPackages = [
  {
    id: 1,
    workOrder: 'BVA202401',
    items: 25,
    dateSent: '01/01/2024',
    expectedReturnDate: '01/15/2024',
    contractor: 'Genesis Government Solutions, Inc.',
    status: 'Sent',
  },
  {
    id: 2,
    workOrder: 'BVA202402',
    items: 1,
    dateSent: '01/01/2024',
    expectedReturnDate: '01/15/2024',
    contractor: 'Jamison Professional Services',
    status: 'Sent',
  },
  {
    id: 3,
    workOrder: 'BVA202403',
    items: 15,
    dateSent: '01/01/2024',
    expectedReturnDate: '01/15/2024',
    contractor: 'Vet Reporting',
    status: 'Sent',
  },
  {
    id: 4,
    workOrder: 'BVA202404',
    items: 5,
    dateSent: '01/08/2024',
    expectedReturnDate: '01/23/2024',
    contractor: 'Genesis Government Solutions, Inc.',
    status: 'Overdue',
  },
  {
    id: 5,
    workOrder: 'BVA202405',
    items: 7,
    dateSent: '01/08/2024',
    expectedReturnDate: '01/23/2024',
    contractor: 'Jamison Professional Services',
    status: 'Sent',
  },
  {
    id: 6,
    workOrder: 'BVA202406',
    items: 11,
    dateSent: '01/08/2024',
    expectedReturnDate: '01/23/2024',
    contractor: 'Jamison Professional Services',
    status: 'Sent',
  },
  {
    id: 7,
    workOrder: 'BVA202407',
    items: 5,
    dateSent: '01/10/2024',
    expectedReturnDate: '01/25/2024',
    contractor: 'Genesis Government Solutions, Inc.',
    status: 'Sent',
  },
  {
    id: 8,
    workOrder: 'BVA202408',
    items: 7,
    dateSent: '01/10/2024',
    expectedReturnDate: '01/25/2024',
    contractor: 'Jamison Professional Services',
    status: 'Sent',
  },
  {
    id: 9,
    workOrder: 'BVA202409',
    items: 11,
    dateSent: '01/10/2024',
    expectedReturnDate: '01/25/2024',
    contractor: 'The Ravens Group, Inc.',
    status: 'Sent',
  },
  {
    id: 10,
    workOrder: 'BVA202410',
    items: 3,
    dateSent: '01/12/2024',
    expectedReturnDate: '01/27/2024',
    contractor: 'Jamison Professional Services',
    status: 'Sent',
  },
  {
    id: 11,
    workOrder: 'BVA202411',
    items: 22,
    dateSent: '01/12/2024',
    expectedReturnDate: '01/27/2024',
    contractor: 'Jamison Professional Services',
    status: 'Sent',
  },
  {
    id: 12,
    workOrder: 'BVA202412',
    items: 14,
    dateSent: '01/12/2024',
    expectedReturnDate: '01/27/2024',
    contractor: 'Vet Reporting',
    status: 'Sent',
  },
  {
    id: 13,
    workOrder: 'BVA202413',
    items: 3,
    dateSent: '01/17/2024',
    expectedReturnDate: '02/01/2024',
    contractor: 'Genesis Government Solutions, Inc.',
    status: 'Sent',
  },
  {
    id: 14,
    workOrder: 'BVA202414',
    items: 22,
    dateSent: '01/17/2024',
    expectedReturnDate: '02/01/2024',
    contractor: 'The Ravens Group, Inc.',
    status: 'Sent',
  },
  {
    id: 15,
    workOrder: 'BVA202415',
    items: 14,
    dateSent: '01/17/2024',
    expectedReturnDate: '02/01/2024',
    contractor: 'The Ravens Group, Inc.',
    status: 'Sent',
  },
];

const mockTranscriptionPackagesResponse = {
  body: {
    task_page_count: 2,
    tasks: {
      data: mockTranscriptionPackages,
    },
    tasks_per_page: 15,
    total_task_count: 18,
  },
};

const mockTranscriptionContractorsResponse = {
  transcription_contractors: [
    {
      id: 1,
      name: 'Genesis Government Solutions, Inc.',
    },
    {
      id: 2,
      name: 'Jamison Professional Services',
    },
    {
      id: 3,
      name: 'The Ravens Group, Inc.',
    },
  ],
};

const selectFilesForPackage = () => '';

const setupUnassignedTable = () =>
  render(
    <TranscriptionFileDispatchTable
      columns={unassignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
      statusFilter={['Unassigned']}
      selectFilesForPackage={selectFilesForPackage}
    />
  );

const setupAssignedTable = () =>
  render(
    <Router>
      <TranscriptionFileDispatchTable
        columns={assignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
        statusFilter={['Assigned']}
      />
    </Router>
  );

const setupCompletedTable = () =>
  render(
    <Router>
      <TranscriptionFileDispatchTable
        columns={completedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
        statusFilter={['Completed']}
      />
    </Router>
  );

const setupAllTable = () =>
  render(
    <Router>
      <TranscriptionFileDispatchTable
        columns={allColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
        statusFilter={['All']}
      />
    </Router>
  );


describe('TranscriptionFileDispatchTable', () => {
  beforeEach(async () => {
    ApiUtil.get = jest.fn();
    ApiUtil.post = jest.fn();

    when(ApiUtil.get).
      calledWith('/hearings/find_by_contractor/available_contractors').
      mockResolvedValue(mockTranscriptionContractorsResponse);

    when(ApiUtil.get).
      calledWith(
        '/hearings/transcription_files/transcription_file_tasks?tab=Unassigned&page=1'
      ).
      mockResolvedValue(mockTranscriptionFilesResponse);

    when(ApiUtil.get).
      calledWith('/hearings/transcription_files/locked').
      mockResolvedValue(mockLockedResponse);

    when(ApiUtil.post).
      calledWith('/hearings/transcription_files/lock', constClickData).
      mockResolvedValue(mockClickedResponse);

    when(ApiUtil.get).
      calledWith(
        '/hearings/transcription_packages/transcription_package_tasks?tab=Assigned&page=1'
      ).
      mockResolvedValue(mockTranscriptionPackagesResponse);

    when(ApiUtil.get).
      calledWith(
        '/hearings/transcription_files/transcription_file_tasks?tab=Completed&page=1'
      ).
      mockResolvedValue(mockCompletedTranscriptionFilesResponse);

    when(ApiUtil.get).
      calledWith(
        '/hearings/transcription_files/transcription_file_tasks?tab=All&page=1'
      ).
      mockResolvedValue(mockAllTranscriptionFilesResponse);

    when(ApiUtil.get).
      calledWith('/hearings/find_by_contractor/filterable_contractors').
      mockResolvedValue(mockTranscriptionContractorsResponse);

    global.setInterval = jest.fn();
  });

  afterEach(() => {
    cleanup();
    jest.clearAllMocks();
  });

  describe('Tabs have no validation issues', () => {
    it('Unassigned tab has no violations', async () => {
      const { container } = setupUnassignedTable();
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('Assigned tab has no violations', async () => {
      const { container } = setupAssignedTable();
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('Completed tab has no violations', async () => {
      const { container } = setupCompletedTable();
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('Unassigned Tab', () => {
    it('loads a table from backend data and handles selected and locked records', async () => {
      const { container } = setupUnassignedTable();

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-15 of 40 total')[0]
        ).toBeInTheDocument()
      );

      const select = container.querySelectorAll('.select-file');
      const checkboxes = container.querySelectorAll('.select-file input');

      expect(checkboxes[0]).toBeChecked();

      expect(checkboxes[1]).toBeDisabled();
      expect(select[1]).toHaveAttribute('title', 'Locked by QATTY2');

      expect(container).toMatchSnapshot();

    });

    it('select all checkbox when select-all checkbox is selected', async () => {
      const { container } = setupUnassignedTable();

      ApiUtil.post.mockResolvedValue(mockSelectAllResponse);
      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-15 of 40 total')[0]
        ).toBeInTheDocument()
      );

      const selectAllCheckbox = screen.getByRole('checkbox', {
        name: /select all files checkbox/i,
      });

      userEvent.click(selectAllCheckbox);

      const selectFileCheckboxes = container.querySelectorAll(
        '.select-file input'
      );

      selectFileCheckboxes.forEach((checkbox) => {
        if (!checkbox.disabled) {
          expect(checkbox).toBeChecked();
        }
      });
      expect(ApiUtil.post).toHaveBeenCalledWith(
        '/hearings/transcription_files/lock',
        selectAllData
      );
    }, 20000);

    it('select individual checkbox when single checkbox is checked', async () => {
      const { container } = setupUnassignedTable();

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-15 of 40 total')[0]
        ).toBeInTheDocument()
      );

      const checkboxes = container.querySelectorAll('.select-file input');

      expect(checkboxes[3]).not.toBeChecked();

      userEvent.click(checkboxes[3]);

      expect(checkboxes[3]).toBeChecked();

      expect(ApiUtil.post).toHaveBeenCalledWith(
        '/hearings/transcription_files/lock',
        constClickData
      );
    }, 20000);

    it('selecting or deselecting an individual checkbox will de-select the "Select All Files" checkbox', async () => {
      const { container } = setupUnassignedTable();

      ApiUtil.post.mockResolvedValue(mockSelectAllResponse);

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-15 of 40 total')[0]
        ).toBeInTheDocument()
      );

      const selectAllCheckbox = screen.getByRole('checkbox', {
        name: /select all files checkbox/i,
      });

      userEvent.click(selectAllCheckbox);

      const individualCheckboxes = container.querySelectorAll(
        '.select-file input'
      );

      individualCheckboxes.forEach((checkbox) => {
        if (!checkbox.disabled) {
          expect(checkbox).toBeChecked();
        }
      });

      userEvent.click(individualCheckboxes[3]);

      expect(individualCheckboxes[3]).not.toBeChecked();

      expect(selectAllCheckbox).not.toBeChecked();

      expect(ApiUtil.post).toHaveBeenCalledWith(
        '/hearings/transcription_files/lock',
        selectAllData
      );
    }, 20000);

    it('allows a user to click to lock a record and call the back end', async () => {
      const { container } = setupUnassignedTable();

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-15 of 40 total')[0]
        ).toBeInTheDocument()
      );

      const checkboxes = container.querySelectorAll('.select-file input');

      expect(checkboxes[3]).not.toBeChecked();

      userEvent.click(checkboxes[3]);

      expect(checkboxes[3]).toBeChecked();
      expect(ApiUtil.post).toHaveBeenCalledWith(
        '/hearings/transcription_files/lock',
        constClickData
      );
    });
  }, 20000);

  describe('Assigned Tab', () => {
    it('loads a table from backend data', async () => {
      const { container } = setupAssignedTable();

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-15 of 18 total')[0]
        ).toBeInTheDocument()
      );

      expect(container).toMatchSnapshot();
    });
  });

  describe('Completed Tab', () => {
    it('loads a table from backend data', async () => {
      const { container } = setupCompletedTable();

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-2 of 2 total')[0]
        ).toBeInTheDocument()
      );

      expect(container).toMatchSnapshot();
    });
  });

  describe('All Tab', () => {
    it('loads a table from backend data', async () => {
      const { container } = setupAllTable();

      await waitFor(() =>
        expect(
          screen.getAllByText('Viewing 1-2 of 2 total')[0]
        ).toBeInTheDocument()
      );

      expect(container).toMatchSnapshot();
    });
  });
});

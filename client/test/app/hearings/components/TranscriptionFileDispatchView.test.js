import React from 'react';
import { TranscriptionFileDispatchView } from '../../../../app/hearings/components/TranscriptionFileDispatchView';
import { render, waitFor, screen, cleanup, fireEvent } from '@testing-library/react';
import ApiUtil from '../../../../app/util/ApiUtil';
import { when } from 'jest-when';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { MemoryRouter as Router } from 'react-router-dom';

const organizations = [
  { name: 'Transcription Dispatch', url: 'hearings/transcription_files' }
];

const setup = () => render(<Router><TranscriptionFileDispatchView organizations={organizations} /></Router>);

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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
  }
];

const mockTranscriptionFilesResponse = {
  body: {
    task_page_count: 3,
    tasks: {
      data: mockTranscriptionFiles
    },
    tasks_per_page: 15,
    total_task_count: 40
  }
};

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

const mockLockedResponse = {
  body: [
    {
      id: 40,
      status: 'selected',
      message: ''
    },
    {
      id: 39,
      status: 'locked',
      message: 'Locked by QATTY2'
    }
  ]
};

const mockTranscriptionContractorsResponse = { body: { transcription_contractors: [] } };

const mockTranscriptionPackagesResponse = {
  body: {
    task_page_count: 1,
    tasks: {
      data: []
    },
    tasks_per_page: 15,
    total_task_count: 0
  }
};

describe('TranscriptionFileDispatch', () => {
  beforeEach(async () => {
    ApiUtil.get = jest.fn();
    ApiUtil.post = jest.fn();

    when(ApiUtil.get).calledWith('/hearings/find_by_contractor/available_contractors').
      mockResolvedValue(mockTranscriptionContractorsResponse);

    when(ApiUtil.get).calledWith('/hearings/transcription_files/transcription_file_tasks?tab=Unassigned&page=1').
      mockResolvedValue(mockTranscriptionFilesResponse);

    when(ApiUtil.get).calledWith('/hearings/transcription_files/locked').
      mockResolvedValue(mockLockedResponse);

    when(ApiUtil.get).calledWith('/hearings/transcription_packages/transcription_package_tasks?tab=Assigned&page=1').
      mockResolvedValue(mockTranscriptionPackagesResponse);

    when(ApiUtil.get).calledWith('/hearings/find_by_contractor/filterable_contractors').
      mockResolvedValue(mockTranscriptionContractorsResponse);

    when(ApiUtil.get).
      calledWith(
        '/hearings/transcription_files/transcription_file_tasks?tab=Completed&page=1'
      ).
      mockResolvedValue(mockCompletedTranscriptionFilesResponse);
    when(ApiUtil.get).
      calledWith(
        '/hearings/transcription_files/transcription_file_tasks?tab=All&page=1'
      ).
      mockResolvedValue(mockCompletedTranscriptionFilesResponse);
  });

  afterEach(() => {
    cleanup();
    jest.clearAllMocks();
  });

  it('has switch views dropdown', () => {
    setup();

    expect(screen.getByText('Switch views')).toBeInTheDocument();
  });

  it('has the correct tabs', () => {
    const { container } = setup();
    const tabs = container.querySelectorAll('.cf-tab');

    expect(tabs).toHaveLength(4);
    expect(tabs[0].textContent).toBe('Unassigned');
    expect(tabs[1].textContent).toBe('Assigned');
    expect(tabs[2].textContent).toBe('Completed');
    expect(tabs[3].textContent).toBe('All transcription');
  });

  it('starts in the unassigned tab', async () => {
    const { container } = setup();

    await waitFor(() =>
      expect(
        screen.getByText(
          'Hearing audio files owned by the Transcription team that are unassigned to a contractor:'
        )
      ).toBeInTheDocument()
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('displays a locked record alert and selected file count', async () => {
    const { container } = setup();

    await waitFor(() =>
      expect(screen.getByText('Another user is in the assignment queue.')).toBeInTheDocument()
    );

    expect(screen.getByText('1 file selected')).toBeInTheDocument();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('PackageFilesModal can be opened', async () => {
    setup();
    const button = screen.getByRole('button', { name: 'Package files' });

    fireEvent.click(button);
    expect(await screen.findByText('Package files')).toBeInTheDocument();
  });

  it('can switch to the assigned tab', async () => {
    const { container } = setup();

    const tabs = container.querySelectorAll('.cf-tab');

    // click to open second tab
    userEvent.click(tabs[1]);

    await waitFor(() =>
      expect(screen.getByText(
        'Work orders owned by the Transcription team that have been sent to a contractor:')).toBeInTheDocument()
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('can switch to the completed tab', async () => {
    const { container } = setup();

    const tabs = container.querySelectorAll('.cf-tab');

    // click to open third tab
    userEvent.click(tabs[2]);

    await waitFor(() =>
      expect(screen.getByText(
        'Work orders owned by the Transcription team that have been returned from a contractor:')).toBeInTheDocument()
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('can switch to the all transcription tab', async () => {
    const { container } = setup();

    const tabs = container.querySelectorAll('.cf-tab');

    // click to open fourth tab
    userEvent.click(tabs[3]);

    await waitFor(() =>
      expect(screen.getByText(
        'All transcription owned by the Transcription team:')).toBeInTheDocument()
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});

import React from 'react';
import { TranscriptionFileDispatchView } from '../../../../app/hearings/components/TranscriptionFileDispatchView';
import { render, waitFor, screen, cleanup } from '@testing-library/react';
import ApiUtil from '../../../../app/util/ApiUtil';
import { when } from 'jest-when';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { MemoryRouter as Router } from 'react-router-dom';

const setup = () => render( <Router><TranscriptionFileDispatchView /></Router>);

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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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
    fileStatus: 'Successful upload (AWS)'
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

const mockClickedResponse = {
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
    },
    {
      id: 38,
      status: 'selected',
      message: ''
    }
  ]
};

const constClickData = { data: { file_ids: [37], status: true } };

describe('TranscriptionFileDispatch', () => {
  beforeEach(async () => {
    ApiUtil.get = jest.fn();
    ApiUtil.post = jest.fn();

    when(ApiUtil.get).calledWith('/hearings/transcription_files/transcription_file_tasks?tab=Unassigned&page=1').
      mockResolvedValueOnce(mockTranscriptionFilesResponse);

    when(ApiUtil.get).calledWith('/hearings/transcription_files/locked').
      mockResolvedValueOnce(mockLockedResponse);

    when(ApiUtil.post).calledWith('/hearings/transcription_files/lock', constClickData).
      mockResolvedValueOnce(mockClickedResponse);
  });

  afterEach(() => {
    cleanup();
    jest.clearAllMocks();
  });

  it('passes a11y', async () => {
    const { container } = setup();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
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

  describe('Unassigned Tab', () => {

    it('loads a table from backend data and handles selected and locked records', async () => {
      const { container } = setup();

      await waitFor(() =>
        expect(screen.getAllByText('Viewing 1-15 of 40 total')[0]).toBeInTheDocument()
      );

      expect(screen.getByText('Another user is in the assignment queue.')).toBeInTheDocument();
      expect(screen.getByText('1 file selected')).toBeInTheDocument();

      const select = container.querySelectorAll('.select-file');
      const checkboxes = container.querySelectorAll('.select-file input');

      expect(checkboxes[0]).toBeChecked();

      expect(checkboxes[1]).toBeDisabled();
      expect(select[1]).toHaveAttribute('title', 'Locked by QATTY2');

      expect(container).toMatchSnapshot();
    });

    it('allows a user to click to lock a record and call the back end', async () => {
      const { container } = setup();

      await waitFor(() =>
        expect(screen.getAllByText('Viewing 1-15 of 40 total')[0]).toBeInTheDocument()
      );

      const checkboxes = container.querySelectorAll('.select-file input');

      expect(checkboxes[3]).not.toBeChecked();

      userEvent.click(checkboxes[3]);

      expect(checkboxes[3]).toBeChecked();
      expect(ApiUtil.post).toHaveBeenCalledWith(
        '/hearings/transcription_files/lock', constClickData);
    });
  });
});

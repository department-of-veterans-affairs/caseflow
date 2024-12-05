import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { WorkOrderDetails } from '../../../../app/hearings/components/WorkOrderDetails';
import ApiUtil from 'app/util/ApiUtil';
import { MemoryRouter } from 'react-router-dom';

jest.mock('app/util/ApiUtil');

describe('WorkOrderDetails', () => {
  const mockTaskNumber = '12345';

  beforeEach(() => {
    jest.resetAllMocks();
  });

  test('should display loading state initially', () => {
    ApiUtil.get.mockImplementation(() => new Promise(() => { }));
    render(
      <MemoryRouter>
        <WorkOrderDetails taskNumber={mockTaskNumber} />
      </MemoryRouter>
    );
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('should display error message when API call fails', async () => {
    ApiUtil.get.mockRejectedValue(new Error('Network Error'));
    render(
      <MemoryRouter>
        <WorkOrderDetails taskNumber={mockTaskNumber} />
      </MemoryRouter>
    );
    await waitFor(() => {
      expect(screen.getByText('Error loading data: Network Error')).toBeInTheDocument();
    });
  });

  test('should display no data found when data is empty', async () => {
    ApiUtil.get.mockResolvedValue({ body: { data: null } });
    render(
      <MemoryRouter>
        <WorkOrderDetails taskNumber={mockTaskNumber} />
      </MemoryRouter>
    );
    await waitFor(() => {
      expect(screen.getByText('No data found')).toBeInTheDocument();
    });
  });

  test('should display data when API call is successful', async () => {
    const mockData = {
      workOrder: '12345',
      returnDate: '2024-09-01',
      contractorName: 'John Doe',
      woFileInfo: [
        { docket_number: '67890', first_name: 'Jane',
          last_name: 'Smith', types: 'Type A', hearing_date: '2024-11-01', regional_office: 'RO1', judge_name: 'Judge Judy', case_type: 'Appeal' },
        { docket_number: '67891', first_name: 'John',
          last_name: 'Doe', types: 'Type B', hearing_date: '2024-11-02', regional_office: 'RO2', judge_name: 'Judge Judy', case_type: 'Appeal' }
      ],
      workOrderStatus: { currentStatus: true }
    };

    ApiUtil.get.mockResolvedValue({ body: { data: mockData } });

    render(
      <MemoryRouter>
        <WorkOrderDetails taskNumber={mockTaskNumber} />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText(/Work order summary #12345/i)).toBeInTheDocument();
      expect(screen.getByText(/Return date:/i)).toBeInTheDocument();
      expect(screen.getByText(/2024-09-01/i)).toBeInTheDocument();
      expect(screen.getByText(/Work order:/i)).toBeInTheDocument();
      expect(screen.getByText(/Contractor:/i)).toBeInTheDocument();
      expect(screen.getByText(/John Doe/i)).toBeInTheDocument();
      expect(screen.getByText('Number of files: 2')).toBeInTheDocument();
    });
  });
});

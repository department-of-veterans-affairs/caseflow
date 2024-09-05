import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { WorkOrderDetails } from '../../../../app/hearings/components/WorkOrderDetails'; // Adjust import based on your file structure
import ApiUtil from 'app/util/ApiUtil';
// Uncomment and adjust the mock for QueueTable if needed
// import QueueTable from 'app/queue/QueueTable';

// Mock the ApiUtil
jest.mock('app/util/ApiUtil');
// Mock QueueTable component if necessary
// jest.mock('app/queue/QueueTable', () => () => <div>QueueTable Component</div>);

describe('WorkOrderDetails', () => {
  const mockTaskNumber = '12345';

  beforeEach(() => {
    jest.resetAllMocks();
  });

  test('should display loading state initially', () => {
    ApiUtil.get.mockImplementation(() => new Promise(() => {})); // Mocking pending promise
    render(<WorkOrderDetails taskNumber={mockTaskNumber} />);
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('should display error message when API call fails', async () => {
    ApiUtil.get.mockRejectedValue(new Error('Network Error'));
    render(<WorkOrderDetails taskNumber={mockTaskNumber} />);
    await waitFor(() => {
      expect(screen.getByText('Error loading data: Network Error')).toBeInTheDocument();
    });
  });

  test('should display no data found when data is empty', async () => {
    ApiUtil.get.mockResolvedValue({ body: { data: null } });
    render(<WorkOrderDetails taskNumber={mockTaskNumber} />);
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
        { docketNumber: '67890', firstName: 'Jane', lastName: 'Smith', types: 'Type A', hearingDate: '2024-11-01', regionalOffice: 'RO1', judgeName: 'Judge Judy', caseType: 'Appeal' },
        { docketNumber: '67891', firstName: 'John', lastName: 'Doe', types: 'Type B', hearingDate: '2024-11-02', regionalOffice: 'RO2', judgeName: 'Judge Judy', caseType: 'Appeal' }
      ]
    };

    ApiUtil.get.mockResolvedValue({ body: { data: mockData } });
    
    render(<WorkOrderDetails taskNumber={mockTaskNumber} />);
    
    await waitFor(() => {
      expect(screen.getByText(/Work order summary #12345/i)).toBeInTheDocument();
      expect(screen.getByText(/Return date:/i)).toBeInTheDocument();
      expect(screen.getByText(/2024-09-01/i)).toBeInTheDocument(); // Adjust if you format the date
      expect(screen.getByText(/Work order:/i)).toBeInTheDocument();
      expect(screen.getByText(/Contractor:/i)).toBeInTheDocument();
      expect(screen.getByText(/John Doe/i)).toBeInTheDocument();
      expect(screen.getByText('Number of files: 2')).toBeInTheDocument();
    });
  });
});

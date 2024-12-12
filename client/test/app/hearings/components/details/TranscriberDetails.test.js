import React from 'react';
import { render } from '@testing-library/react';
import TranscriberDetails from 'app/hearings/components/details/TranscriberDetails';
import StringUtil from 'app/util/StringUtil';

jest.mock('app/util/StringUtil', () => ({
  capitalizeFirst: jest.fn((str) => str.charAt(0).toUpperCase() + str.slice(1)),
  sanitize: jest.fn((str) => str),
}));

describe('TranscriberDetails', () => {
  const hearing = {
    conferenceProvider: 'recording service',
    scheduledTime: '2024-09-24T10:00:00Z',
    dateReceiptRecording: '2024-09-25T10:00:00Z',
  };

  test('renders all details correctly', () => {
    const { getByText } = render(<TranscriberDetails hearing={hearing} />);

    expect(getByText(/Recorder/i)).toBeInTheDocument();
    expect(getByText(/Recording service/i)).toBeInTheDocument();
    expect(getByText(/Recording date/i)).toBeInTheDocument();
    expect(getByText(/2024-09-24T10:00:00Z/i)).toBeInTheDocument();
    expect(getByText(/Retrieval date/i)).toBeInTheDocument();
    expect(getByText(/2024-09-25T10:00:00Z/i)).toBeInTheDocument();
  });

  test('renders N/A when hearing is missing', () => {
    const { getAllByText } = render(<TranscriberDetails hearing={{}} />);
    const naElements = getAllByText(/N\/A/i);

    expect(naElements.length).toBe(3);
  });

  test('capitalizes the service name correctly', () => {
    StringUtil.capitalizeFirst.mockImplementation((str) => {
      return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
    });
    const { getByText } = render(<TranscriberDetails hearing={hearing} />);

    expect(getByText(/Recording service/i)).toBeInTheDocument();
  });
});

import React from 'react';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { render as rtlRender, screen } from '@testing-library/react';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import { anyUser, amaHearing, defaultHearing } from 'test/data';
import superagent from 'superagent';

jest.mock('superagent');

const mockJudges = [
  { id: 'judge1', name: 'Judge Judy' },
  { id: 'judge2', name: 'Judge Dredd' },
];

// Setup the mock implementation
superagent.get.mockImplementation((url) => {
  const mockResponse = { body: mockJudges };
  const mockRequest = {
    set: jest.fn().mockReturnThis(),
    query: jest.fn().mockReturnThis(),
    timeout: jest.fn().mockReturnThis(),
    on: jest.fn().mockReturnThis(),
    use: jest.fn().mockReturnThis(), // Add the `use` method
    then: jest.fn((callback) => {
      callback(mockResponse);
      return Promise.resolve(mockResponse);
    }),
    catch: jest.fn(() => Promise.resolve(mockResponse)),
  };

  if (url === '/users?role=Judge') {
    return mockRequest;
  } else {
    return Promise.reject(new Error('connect ECONNREFUSED 127.0.0.1:80'));
  }
});

function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return rtlRender(ui, options);
}

const Wrapper = ({ children, user, hearing, store }) => {
  const HearingDetails = hearingDetailsWrapper(user, hearing);
  return (
    <HearingDetails store={store}>
      {children}
    </HearingDetails>
  );
};

describe('DetailsForm', () => {
  test('Matches snapshot with default props when passed in', async () => {
    const { asFragment } = customRender(
      <DetailsForm
      hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    expect(asFragment()).toMatchSnapshot();

    const element = document.getElementById('hearingEmailEvents');
    expect(element).not.toBeInTheDocument();
  });

  test('Matches snapshot with for legacy hearing', () => {
    const { asFragment } = customRender(
      <DetailsForm
      isLegacy
      hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    expect(asFragment()).toMatchSnapshot();

    const hearingTypeInput = screen.getByRole('combobox', { name: /hearing type/i });
    expect(hearingTypeInput).toBeInTheDocument();

    const transcriptionDetails = screen.queryByText('Transcription Details');
    expect(transcriptionDetails).not.toBeInTheDocument
  });

  test('Matches snapshot with for AMA hearing', () => {
    const { asFragment } = customRender(
      <DetailsForm
      isLegacy={false}
      hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    expect(asFragment()).toMatchSnapshot();

    const hearingTypeInput = screen.getByRole('combobox', { name: /hearing type/i });
    expect(hearingTypeInput).toBeInTheDocument();

    const transcriptionDetails = screen.getByRole('heading', { name: /transcription details/i });
    expect(transcriptionDetails).toBeInTheDocument();

    const checkbox = screen.getByRole('checkbox', { name: /evidenceWindowWaived/i });
    expect(checkbox).toBeInTheDocument();
  });
});

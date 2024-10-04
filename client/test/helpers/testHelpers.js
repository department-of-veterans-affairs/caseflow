import React from 'react';
import { screen } from '@testing-library/react';
import superagent from 'superagent';
import { render as rtlRender } from '@testing-library/react';
import { hearingDetailsWrapper } from 'test/data/stores/hearingsStore';

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
    use: jest.fn().mockReturnThis(),
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

export const Wrapper = ({ children, user, hearing, judge, store }) => {
  const HearingDetails = hearingDetailsWrapper(user, hearing, judge);
  return (
    <HearingDetails store={store}>
      {children}
    </HearingDetails>
  );
};

export function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options } = {}) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return rtlRender(ui, options);
}

export const testRenderingWithNewProps = async (setupFn) => {
  const newProps = {
    cancelText: 'cancel',
    skipText: 'skip',
    submitText: 'submit'
  };

  setupFn(newProps);

  const cancelBtn = await screen.findByText('cancel');
  const skipBtn = await screen.findByText('skip');
  const submitBtn = await screen.findByText('submit');

  expect(cancelBtn.textContent).toBe('cancel');
  expect(skipBtn.textContent).toBe('skip');
  expect(submitBtn.textContent).toBe('submit');
};

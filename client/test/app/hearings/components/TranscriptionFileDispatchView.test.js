import React from 'react';
import { TranscriptionFileDispatchView } from '../../../../app/hearings/components/TranscriptionFileDispatchView';
import { render } from '@testing-library/react';

const setup = () => render(<TranscriptionFileDispatchView />);

describe('TranscriptionFileDispatch', () => {

  it('matches snapshot', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

});

/*

import { axe } from 'jest-axe';

it('passes a11y', async () => {
  const { container } = setup();
  const results = await axe(container);

  expect(results).toHaveNoViolations();
});

it('has title', () => {
  setup();

  expect(screen.getByText('Transcription file dispatch')).toBeInTheDocument();
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

it('renders template of unassigned tab', () => {
  const { container } = setup();
  const packageButton = container.querySelector('.usa-button-disabled');

  expect(
    screen.getByText('Please select the files you would like to dispatch for transcription:')
  ).toBeInTheDocument();

  expect(
    screen.getByText('Transcription settings')
  ).toBeInTheDocument();

  expect(
    screen.getByText('Search by Docket Number, Claimant Name, File Number, or SSN')
  ).toBeInTheDocument();

  expect(packageButton.textContent).toBe('Package files');
});

*/

import React from 'react';
import {
  screen,
  render,
  fireEvent,
  within,
  act,
  waitFor,
} from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { STATES } from 'app/constants/AppConstants';

import COPY from 'app/../COPY';

import { AddClaimantPage } from 'app/intake/addClaimant/AddClaimantPage';
import { IntakeProviders } from '../../testUtils';
import { fillForm, relationshipOpts } from './testUtils';

describe('AddClaimantPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onSubmit, onBack };
  const setup = () => {
    return render(<AddClaimantPage {...defaults} />, {
      wrapper: IntakeProviders,
    });
  };

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    expect(screen.getByText('Add Claimant')).toBeInTheDocument();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('fires onBack', async () => {
    setup();

    const backButton = screen.getByRole('button', { name: /back/i });

    expect(onBack).not.toHaveBeenCalled();

    await userEvent.click(backButton);
    await waitFor(() => {
      expect(onBack).not.toHaveBeenCalled();
    });
  });

  describe('form validation', () => {
    it('disables submit button unless valid', async () => {
      setup();

      const submit = screen.getByRole('button', {
        name: /Continue to next step/i,
      });

      // submit button disabled
      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      // Select option
      await selectEvent.select(
        screen.getByLabelText('Relationship to the Veteran'),
        [relationshipOpts[3].label]
      );

      // Set organization
      await userEvent.click(
        screen.getByRole('radio', { name: /organization/i })
      );

      // Wait for form to re-render
      await waitFor(() => {
        expect(
          screen.getByRole('textbox', { name: /Organization name/i })
        ).toBeInTheDocument();
      });

      await fillForm();
      // trigger onBlur
      userEvent.tab();
      // submit button enabled
      await waitFor(() => {
        expect(submit).not.toBeDisabled();
      });
    }, 15000);
  });
});

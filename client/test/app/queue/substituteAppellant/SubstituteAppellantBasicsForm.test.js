import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import {
  SubstituteAppellantBasicsForm,
  subDateMinErrorMsg,
} from 'app/queue/substituteAppellant/basics/SubstituteAppellantBasicsForm';
import { add, format, parseISO, sub } from 'date-fns';

const relationships = [
  { value: '123456', displayText: 'John Doe, Spouse' },
  { value: '654321', displayText: 'Jen Doe, Child' },
];

describe('SubstituteAppellantBasicsForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();

  const defaults = {
    onCancel,
    onSubmit,
    relationships,
    nodDate: '2021-05-15',
    dateOfDeath: '2021-06-01',
  };

  const setup = (props) =>
    render(<SubstituteAppellantBasicsForm {...defaults} {...props} />);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('fires onCancel', async () => {
    setup();
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('with blank form', () => {
    it('renders default state correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    describe('form validation', () => {
      it('requires entry of substitution date', async () => {
        setup();

        const submit = screen.getByRole('button', { name: /continue/i });

        // Submit to trigger validation
        await userEvent.click(submit);

        expect(onSubmit).not.toHaveBeenCalled();

        await waitFor(() => {
          expect(
            screen.getByText(/substitution date is required/i)
          ).toBeInTheDocument();
        });
      });

      it('requires substitution date to be after NOD date', async () => {
        setup();

        const subDateInput = screen.getByLabelText(
          /when was substitution granted/i
        );
        const invalidDate = format(add(parseISO(defaults.nodDate), { days: 5 }), 'yyyy-MM-dd');

        // Enter date
        fireEvent.change(subDateInput, { target: { value: invalidDate } });

        const submit = screen.getByRole('button', { name: /continue/i });

        // Submit to trigger validation
        await userEvent.click(submit);

        expect(onSubmit).not.toHaveBeenCalled();

        await waitFor(() => {
          expect(screen.getByText(subDateMinErrorMsg)).toBeInTheDocument();
        });
      });

      it('requires substitution date to be after date of death', async () => {
        const earlierDateOfDeath = format(sub(parseISO(defaults.nodDate), { days: 10 }), 'yyyy-MM-dd');

        setup({ dateOfDeath: earlierDateOfDeath });

        const subDateInput = screen.getByLabelText(
          /when was substitution granted/i
        );
        const invalidDate = format(add(parseISO(earlierDateOfDeath), { days: 5 }), 'yyyy-MM-dd');

        // Enter date
        fireEvent.change(subDateInput, { target: { value: invalidDate } });

        const submit = screen.getByRole('button', { name: /continue/i });

        // Submit to trigger validation
        await userEvent.click(submit);

        expect(onSubmit).not.toHaveBeenCalled();

        await waitFor(() => {
          expect(screen.getByText(subDateMinErrorMsg)).toBeInTheDocument();
        });
      });

      it('requires selection of existing relationship', async () => {
        setup();

        await userEvent.click(
          screen.getByRole('button', { name: /continue/i })
        );

        expect(onSubmit).not.toHaveBeenCalled();

        await waitFor(() => {
          expect(
            screen.getByText(/you must select a claimant/i)
          ).toBeInTheDocument();
        });
      });
    });
  });

  describe('with existing form data', () => {
    const existingValues = {
      substitutionDate: '2021-06-15',
      participantId: relationships[1].value,
    };

    it('renders default state correctly', () => {
      const { container } = setup({ existingValues });

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setup({ existingValues });

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    describe('form validation', () => {
      it('fires onSubmit because everything is good to go', async () => {
        setup({ existingValues });

        const submit = screen.getByRole('button', { name: /continue/i });

        // Submit to trigger validation
        await userEvent.click(submit);

        await waitFor(() => {
          expect(onSubmit).toHaveBeenCalled();
        });
      });
    });
  });
});

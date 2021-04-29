import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { parseISO } from 'date-fns';

import { SubstituteAppellantTasksForm } from 'app/queue/substituteAppellant/tasks/SubstituteAppellantTasksForm';
import { MemoryRouter } from 'react-router';

describe('SubstituteAppellantTasksForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();

  const defaults = {
    appealId: 'abc123',
    nodDate: parseISO('2021-04-01'),
    dateOfDeath: parseISO('2021-04-15'),
    substitutionDate: parseISO('2021-04-20'),
    onCancel,
    onSubmit,
  };

  const setup = (props) =>
    render(
      <MemoryRouter>
        <SubstituteAppellantTasksForm {...defaults} {...props} />
      </MemoryRouter>
    );

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

    // describe('form validation', () => {
    //   it('requires at least some tasks to have been entered', async () => {
    //     setup();

    //     const submit = screen.getByRole('button', { name: /continue/i });

    //     // Submit to trigger validation
    //     await userEvent.click(submit);

    //     expect(onSubmit).not.toHaveBeenCalled();
    //   });
    // });
  });

  describe('with existing form data', () => {
    const existingValues = {
      // Insert task data here
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
      it('is valid with proper existing values', async () => {
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

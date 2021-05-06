import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { parseISO } from 'date-fns';
import { MemoryRouter } from 'react-router';

import { SubstituteAppellantTasksForm } from 'app/queue/substituteAppellant/tasks/SubstituteAppellantTasksForm';
import { sampleEvidenceSubmissionTasks } from 'test/data/queue/substituteAppellant/tasks';

describe('SubstituteAppellantTasksForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();

  // Date constructor uses zero-based offset for months — this is 2021-03-17
  const fakeDate = new Date(2021, 2, 17, 12);

  beforeAll(() => {
  // Ensure consistent handling of dates across tests
    jest.useFakeTimers('modern');
    jest.setSystemTime(fakeDate);
  });

  afterAll(() => {
    // Reset normal timers
    jest.useRealTimers();
  });

  const defaults = {
    appealId: 'abc123',
    nodDate: parseISO('2021-04-01'),
    dateOfDeath: parseISO('2021-04-15'),
    substitutionDate: parseISO('2021-04-20'),
    tasks: sampleEvidenceSubmissionTasks(),
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
      // Fake timers causes timeouts for jest-axe
      jest.useRealTimers();
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
      jest.useFakeTimers('modern');
    });
  });

  describe('with existing form data', () => {
    const existingValues = {
      // Insert task data here
      taskIds: [2, 3]
    };

    it('renders default state correctly', () => {
      const { container } = setup({ existingValues });

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      // Fake timers causes timeouts for jest-axe
      jest.useRealTimers();
      const { container } = setup({ existingValues });

      const results = await axe(container);

      expect(results).toHaveNoViolations();
      jest.useFakeTimers('modern');
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

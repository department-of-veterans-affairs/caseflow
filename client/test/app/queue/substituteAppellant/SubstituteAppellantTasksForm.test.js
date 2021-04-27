import React from 'react';
import { act, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
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

  describe('additional admin actions', () => {
    const clickAddTask = () =>
      userEvent.click(screen.getByRole('button', { name: /add task/i }));

    it('shows the form when button is pressed', async () => {
      setup();

      clickAddTask();

      expect(
        screen.getByRole('textbox', { name: /select the type of task/i })
      ).toBeInTheDocument();

      expect(
        screen.getByRole('textbox', { name: /instructions/i })
      ).toBeInTheDocument();

      expect(
        screen.getByRole('button', { name: /remove/i })
      ).toBeInTheDocument();

      // Still only one "Add Task" button
      expect(
        screen.queryAllByRole('button', { name: /add task/i }).length
      ).toBe(1);
    });

    it('supports adding multiple tasks', async () => {
      setup();

      clickAddTask();

      expect(
        screen.queryAllByRole('textbox', { name: /select the type of task/i }).
          length
      ).toBe(1);

      expect(
        screen.queryAllByRole('textbox', { name: /instructions/i }).length
      ).toBe(1);

      // Add a second task
      clickAddTask();

      expect(
        screen.queryAllByRole('textbox', { name: /select the type of task/i }).
          length
      ).toBe(2);

      expect(
        screen.queryAllByRole('textbox', { name: /instructions/i }).length
      ).toBe(2);

      expect(screen.queryAllByRole('button', { name: /remove/i }).length).toBe(
        2
      );

      // Still only one "Add Task" button
      expect(
        screen.queryAllByRole('button', { name: /add task/i }).length
      ).toBe(1);
    });

    it('submits added tasks', async () => {
      setup();

      clickAddTask();

      await selectEvent.select(
        screen.getByLabelText(/select the type of task/i),
        'IHP'
      );

      userEvent.type(
        screen.getByRole('textbox', { name: /instructions/i }),
        'foo bar'
      );

      await act(async () => {
        await userEvent.click(
          screen.getByRole('button', { name: /continue/i })
        );
      });

      expect(onSubmit.mock.calls[0][0]?.newTasks?.length).toBe(1);
      expect(onSubmit.mock.calls[0][0]?.newTasks?.[0]).toEqual(
        expect.objectContaining({
          type: 'IhpColocatedTask',
          instructions: 'foo bar',
        })
      );
    });
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

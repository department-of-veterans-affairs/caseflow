import React from 'react';
import { render, screen, within, act, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { DocketSwitchEditTasksForm } from 'app/queue/docketSwitch/grant/DocketSwitchEditTasksForm';
import {
  DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL,
  DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';

describe('DocketSwitchEditTasksForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const onBack = jest.fn();
  const docketFrom = 'direct_review';
  const docketTo = 'hearing';
  const taskListing = [
    { taskId: 1, appealId: 1, type: 'TaskTypeA', label: 'Task Type A' },
    { taskId: 2, appealId: 1, type: 'TaskTypeB', label: 'Task Type B' },
    { taskId: 3, appealId: 1, type: 'TaskTypeC', label: 'Task Type C' },
  ];

  const defaults = {
    docketFrom,
    docketTo,
    onBack,
    onCancel,
    onSubmit,
    taskListing,
  };

  const setup = (props) =>
    render(<DocketSwitchEditTasksForm {...defaults} {...props} />);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    expect(
      screen.getByText(DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL)
    ).toBeInTheDocument();

    expect(
      screen.getByText('You are switching from Direct Review to Hearing')
    ).toBeInTheDocument();

    expect(
      screen.getByText('Please unselect any tasks you would like to remove:')
    ).toBeInTheDocument();

    for (const task of taskListing) {
      expect(screen.getByText(task.label)).toBeInTheDocument();
    }
  });

  it('fires onCancel', async () => {
    render(<DocketSwitchEditTasksForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  it('fires onBack', async () => {
    render(<DocketSwitchEditTasksForm {...defaults} />);
    expect(onBack).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /back/i }));
    expect(onBack).toHaveBeenCalled();
  });

  it('fires onSubmit', async () => {
    render(<DocketSwitchEditTasksForm {...defaults} />);
    expect(onSubmit).not.toHaveBeenCalled();

    // submit and wait for async validation
    await act(async () =>
      userEvent.click(screen.getByRole('button', { name: /continue/i }))
    );

    expect(onSubmit).toHaveBeenCalled();
  });

  describe('existing tasks', () => {
    const triggerModal = () => {
      const checkboxGroup = screen.getByRole('group', {
        name: /please unselect any tasks/i,
      });

      userEvent.click(
        within(checkboxGroup).getByRole('checkbox', {
          name: /task type b/i,
        })
      );
    };

    it('displays confirmation modal when existing task is deselected', () => {
      setup();

      triggerModal();

      // Modal visible
      expect(screen.getByText(/confirm removing task/i)).toBeInTheDocument();

      // Cancel modal
      userEvent.click(
        within(screen.getByRole('dialog')).getByRole('button', {
          name: /cancel/i,
        })
      );
      expect(
        screen.queryByText(/confirm removing task/i)
      ).not.toBeInTheDocument();

      // Open modal again
      triggerModal();

      // Confirm/submit modal
      userEvent.click(
        within(screen.getByRole('dialog')).getByRole('button', {
          name: /confirm/i,
        })
      );
      expect(
        screen.queryByText(/confirm removing task/i)
      ).not.toBeInTheDocument();
    });

    it('closes confirmation modal when canceled', () => {
      setup();

      triggerModal();

      // Modal visible
      expect(screen.getByText(/confirm removing task/i)).toBeInTheDocument();

      // Cancel modal
      userEvent.click(
        within(screen.getByRole('dialog')).getByRole('button', {
          name: /cancel/i,
        })
      );
      expect(
        screen.queryByText(/confirm removing task/i)
      ).not.toBeInTheDocument();
    });

    it('updates selected tasks when confirmed', async () => {
      setup();

      triggerModal();

      // Modal visible
      expect(screen.getByText(/confirm removing task/i)).toBeInTheDocument();

      // Confirm/submit modal
      userEvent.click(
        within(screen.getByRole('dialog')).getByRole('button', {
          name: /confirm/i,
        })
      );
      expect(
        screen.queryByText(/confirm removing task/i)
      ).not.toBeInTheDocument();

      // Submit form and check values
      await act(async () =>
        userEvent.click(screen.getByRole('button', { name: /continue/i }))
      );
      expect(onSubmit).toHaveBeenCalled();

      // Should only return the two selected tasks
      expect(onSubmit.mock.calls[0][0]?.taskIds?.length).toBe(2);
    });

    describe('no existing tasks', () => {
      it('renders alternate text', () => {
        setup({ taskListing: [] });

        expect(
          screen.getByText(/there are currently no open tasks on this appeal/i)
        ).toBeInTheDocument();
      });
    });
  });

  describe('mandatory tasks', () => {
    it('shows the correct mandatory tasks', () => {
      setup();

      const mandatoryGroup = screen.getByRole('group', {
        name: /automatically be created/i,
      });

      expect(within(mandatoryGroup).queryAllByRole('checkbox').length).toBe(2);
    });
  });

  describe('additional admin actions', () => {
    const clickAddTask = () =>
      userEvent.click(screen.getByRole('button', { name: /add task/i }));

    it('shows the form when button is pressed', async () => {
      setup();

      clickAddTask();

      expect(
        screen.getByRole('combobox', { name: /select the type of task/i })
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
        screen.queryAllByRole('combobox', { name: /select the type of task/i }).
          length
      ).toBe(1);

      expect(
        screen.queryAllByRole('textbox', { name: /instructions/i }).length
      ).toBe(1);

      // Add a second task
      clickAddTask();

      expect(
        screen.queryAllByRole('combobox', { name: /select the type of task/i }).
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

  describe('default values', () => {
    let defaultValues;

    beforeEach(() => {
      defaultValues = {
        taskIds: ['1', '3'],
        newTasks: [
          { type: 'AojColocatedTask', instructions: 'Lorem ipsum and whatnot' },
        ],
      };
    });

    it('populates with default values', async () => {
      const { container } = setup({ defaultValues });

      expect(container).toMatchSnapshot();

      const submit = screen.getByRole('button', { name: /Continue/i });

      expect(submit).toBeEnabled();
      await userEvent.click(submit);
      await waitFor(() => {
        expect(onSubmit).toHaveBeenLastCalledWith(
          expect.objectContaining({
            ...defaultValues
          }),
          expect.anything()
        );
      });
    });
  });
});

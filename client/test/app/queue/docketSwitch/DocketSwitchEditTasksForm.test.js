import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DocketSwitchEditTasksForm } from 'app/queue/docketSwitch/grant/DocketSwitchEditTasksForm';
import {
  DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL,
  DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';

describe('DocketSwitchEditTasksForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const onBack  = jest.fn();
  const docketFrom = 'Direct Review';
  const docketTo = 'Hearing';
  const tasks = [
  { taskId: 1, appealId: 1, type: 'TaskTypeA', label: 'Task Type A' },
  { taskId: 2, appealId: 1, type: 'TaskTypeB', label: 'Task Type B' },
  { taskId: 3, appealId: 1, type: 'TaskTypeC', label: 'Task Type C' },
];

const defaults = { onSubmit, onCancel,onBack, tasks, docketFrom, docketTo };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(
      <DocketSwitchEditTasksForm {...defaults} />
    );

    expect(container).toMatchSnapshot();
     expect(
      screen.getByText(DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL)
    ).toBeInTheDocument();

  });

  it('fires onCancel', async () => {
    render(<DocketSwitchEditTasksForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();
    expect(screen.getByText('Please unselect any tasks you would like to remove:')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });
});

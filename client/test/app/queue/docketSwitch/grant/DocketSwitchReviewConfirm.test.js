import React from 'react';
import { render, screen, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { sub } from 'date-fns';
import { DocketSwitchReviewConfirm } from 'app/queue/docketSwitch/grant/DocketSwitchReviewConfirm';
import {
  DOCKET_SWITCH_GRANTED_CONFIRM_TITLE,
  DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B,
} from 'app/../COPY';

describe('DocketSwitchReviewConfirm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const onBack = jest.fn();
  const docketFrom = 'direct_review';
  const docketTo = 'hearing';
  const tasks = [
    {
      taskId: 1,
      appealId: 1,
      type: 'TaskTypeA',
      label: 'Task Type A',
      instructions: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
    },
    {
      taskId: 2,
      appealId: 1,
      type: 'TaskTypeB',
      label: 'Task Type B',
      instructions: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
    },
    {
      taskId: 3,
      appealId: 1,
      type: 'TaskTypeC',
      label: 'Task Type C',
      instructions: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
    },
  ];

  const decisionDate = sub(new Date('2021-02-01'), { days: 10 });

  const issues = [
    {
      id: 1,
      program: 'compensation',
      description: 'PTSD denied',
      decision_date: decisionDate,
    },
    {
      id: 2,
      program: 'compensation',
      description: 'Left knee denied',
      decision_date: decisionDate,
    },
    {
      id: 3,
      program: 'compensation',
      description: 'Right knee denied',
      decision_date: decisionDate,
    },
    {
      id: 4,
      program: 'compensation',
      description: 'Right knee granted at 90%',
      decision_date: decisionDate,
    },
  ];

  const defaults = {
    docketFrom,
    docketTo,
    onBack,
    onCancel,
    onSubmit,
    originalReceiptDate: sub(new Date('2021-02-01'), { days: 30 }),
    docketSwitchReceiptDate: sub(new Date('2021-02-01'), { days: 7 }),
    issuesSwitched: issues,
    tasksKept: tasks,
    veteranName: 'Foo Bar',
  };

  const setup = (props) =>
    render(<DocketSwitchReviewConfirm {...defaults} {...props} />);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    expect(
      screen.getByText(DOCKET_SWITCH_GRANTED_CONFIRM_TITLE)
    ).toBeInTheDocument();

    expect(
      screen.getByText(DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B)
    ).toBeInTheDocument();

    expect(
      screen.getByText(
        [
          'You are switching from Direct Review to Hearing.',
          'Tasks specific to the Direct Review docket will be automatically removed,',
          'and tasks associated with the Hearing docket will be automatically created.',
        ].join(' ')
      )
    ).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    setup();
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  it('fires onBack', async () => {
    setup();
    expect(onBack).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /back/i }));
    expect(onBack).toHaveBeenCalled();
  });

  it('fires onSubmit', async () => {
    setup();
    expect(onSubmit).not.toHaveBeenCalled();

    // submit and wait for async validation
    await act(async () =>
      userEvent.click(
        screen.getByRole('button', { name: /confirm docket switch/i })
      )
    );

    expect(onSubmit).toHaveBeenCalled();
  });

  describe('full grant', () => {
    it('renders issues correctly', async () => {
      setup();

      expect(
        screen.getByText('Issues switched to new docket')
      ).toBeInTheDocument();

      expect(
        screen.queryByText('Issues on original docket')
      ).not.toBeInTheDocument();
    });
  });

  describe('with alternate claimant', () => {
    it('renders the claimant row', async () => {
      const { container } = setup({ claimantName: 'Jane Doe' });

      expect(container).toMatchSnapshot();
    });
  });
});

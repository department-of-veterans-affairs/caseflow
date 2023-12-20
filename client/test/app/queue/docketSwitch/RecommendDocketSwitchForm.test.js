import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';

import { RecommendDocketSwitchForm } from 'app/queue/docketSwitch/recommendDocketSwitch/RecommendDocketSwitchForm';
import {
  DOCKET_SWITCH_RECOMMENDATION_TITLE,
  DOCKET_SWITCH_RECOMMENDATION_INSTRUCTIONS,
} from 'COPY';
import { sprintf } from 'sprintf-js';

const judgeOptions = [
  { label: 'VLJ Jane Doe', value: 1 },
  { label: 'VLJ John Doe', value: 2 },
];

describe('RecommendDocketSwitchForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const defaults = { onSubmit, onCancel, appellantName, judgeOptions };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<RecommendDocketSwitchForm {...defaults} />);

    expect(container).toMatchSnapshot();

    expect(screen.getByText(sprintf(DOCKET_SWITCH_RECOMMENDATION_TITLE, appellantName))).toBeInTheDocument();
    expect(screen.getByText(DOCKET_SWITCH_RECOMMENDATION_INSTRUCTIONS)).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    render(<RecommendDocketSwitchForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation', () => {
    it('disables submit until all fields valid', async () => {
      render(<RecommendDocketSwitchForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /submit/i });

      const timelyGroup = screen.getByRole('group', { name: /timely/i });

      expect(onSubmit).not.toHaveBeenCalled();

      await userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      // We need to wrap this in waitFor due to async nature of form validation
      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      await userEvent.type(
        screen.getByLabelText('Add a summary of the request to switch dockets:'),
        'Summary instructions for docket switch'
      );

      //   Set timely
      await userEvent.click(
        screen.getByRole('radio', { container: timelyGroup, name: /yes/i })
      );

      //   Set disposition
      await userEvent.click(
        screen.getByRole('radio', { name: /grant all issues/i })
      );

      //   Select a judge
      await selectEvent.select(
        screen.getByLabelText(/assign to judge/i),
        judgeOptions[1].label
      );

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);
      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });
  });

  it('fires onSubmit with correct values', async () => {
    const summary = 'Lorem ipsum';
    const hyperlink = 'https://example.com/file.txt';

    render(<RecommendDocketSwitchForm {...defaults} />);

    const submit = screen.getByRole('button', { name: /submit/i });
    const timelyGroup = screen.getByRole('group', { name: /timely/i });

    //   Set timely
    await userEvent.click(
      screen.getByRole('radio', { container: timelyGroup, name: /yes/i })
    );

    //   Set disposition
    await userEvent.click(
      screen.getByRole('radio', { name: /grant all issues/i })
    );

    //   Select a judge
    await selectEvent.select(
      screen.getByLabelText(/assign to judge/i),
      judgeOptions[1].label
    );

    await userEvent.type(
      screen.getByRole('textbox', { name: /summary/i }),
      summary
    );
    await userEvent.type(
      screen.getByRole('textbox', { name: /hyperlink/i }),
      hyperlink
    );

    await userEvent.click(submit);

    waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        timely: 'yes',
        disposition: 'granted',
        hyperlink,
        summary,
        judge: judgeOptions[1],
      });
    });
  });

  it('allows setting default judge', async () => {
    render(
      <RecommendDocketSwitchForm
        {...defaults}
        defaultJudgeId={judgeOptions[1].value}
      />
    );

    // This one
    expect(screen.queryByText(judgeOptions[1].label)).toBeTruthy();

    // Not this one
    expect(screen.queryByText(judgeOptions[0].label)).not.toBeTruthy();
  });
});

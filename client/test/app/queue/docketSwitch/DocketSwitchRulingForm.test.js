import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';

import { DocketSwitchRulingForm } from 'app/queue/docketSwitch/judgeRuling/DocketSwitchRulingForm';
import {
  DOCKET_SWITCH_RULING_TITLE,
  DOCKET_SWITCH_RULING_INSTRUCTIONS,
} from 'COPY';
import { sprintf } from 'sprintf-js';

const attorneyOptions = [
  { label: 'Attorney 1', value: 1 },
  { label: 'Attorney 2', value: 2 },
];

describe('DocketSwitchRulingForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const instructions = ["**Summary:** Summary\n\n**Is this a timely request:** Yes\n\n**Recommendation:** Grant all issues\n\n**Draft letter:** http://www.va.gov"];
  const defaults = { onSubmit, onCancel, appellantName, attorneyOptions, instructions };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<DocketSwitchRulingForm {...defaults} />);

    expect(container).toMatchSnapshot();

    expect(screen.getByText(sprintf(DOCKET_SWITCH_RULING_TITLE, appellantName))).toBeInTheDocument();
    expect(screen.getByText(DOCKET_SWITCH_RULING_INSTRUCTIONS)).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    render(<DocketSwitchRulingForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation', () => {
    it('disables submit until all fields valid', async () => {
      render(<DocketSwitchRulingForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /submit/i });

      expect(onSubmit).not.toHaveBeenCalled();

      await userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      // We need to wrap this in waitFor due to async nature of form validation
      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      //   Set disposition
      await userEvent.click(
        screen.getByRole('radio', { name: /grant all issues/i })
      );

      //   Select an attorney
      await selectEvent.select(
        screen.getByLabelText(/assign to office of the clerk of the board/i),
        attorneyOptions[1].label
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
    const context = 'Lorem ipsum';
    const hyperlink = 'https://example.com/file.txt';

    render(<DocketSwitchRulingForm {...defaults} />);

    const submit = screen.getByRole('button', { name: /submit/i });

    //   Set disposition
    await userEvent.click(
      screen.getByRole('radio', { name: /grant all issues/i })
    );

    //   Select a attorney
    await selectEvent.select(
      screen.getByLabelText(/assign to office of the clerk of the board/i),
      attorneyOptions[1].label
    );

    await userEvent.type(
      screen.getByRole('textbox', { name: /context/i }),
      context
    );
    await userEvent.type(
      screen.getByRole('textbox', { name: /hyperlink/i }),
      hyperlink
    );

    await userEvent.click(submit);

    waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        disposition: 'granted',
        hyperlink,
        context,
        attorney: attorneyOptions[1],
      });
    });
  });

  it('allows setting default attorney', async () => {
    render(
      <DocketSwitchRulingForm
        {...defaults}
        defaultJudgeId={attorneyOptions[1].value}
      />
    );

    // This one
    expect(screen.queryByText(attorneyOptions[1].label)).toBeTruthy();

    // Not this one
    expect(screen.queryByText(attorneyOptions[0].label)).not.toBeTruthy();
  });
});

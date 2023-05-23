import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import ReactMarkdown from 'react-markdown';

import { DocketSwitchRulingForm } from 'app/queue/docketSwitch/judgeRuling/DocketSwitchRulingForm';
import {
  DOCKET_SWITCH_RULING_TITLE,
  DOCKET_SWITCH_RULING_INSTRUCTIONS,
} from 'COPY';
import { sprintf } from 'sprintf-js';

const clerkOfTheBoardAttorneys = [
  { label: 'Attorney 1', value: 1 },
  { label: 'Attorney 2', value: 2 },
];

describe('DocketSwitchRulingForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const instructions = ["**Summary:** Summary\n\n**Is this a timely request:** Yes\n\n**Recommendation:** Grant all issues\n\n**Draft letter:** http://www.va.gov"];
  const defaults = { onSubmit, onCancel, appellantName, clerkOfTheBoardAttorneys, instructions };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<DocketSwitchRulingForm {...defaults} />);

    expect(container).toMatchSnapshot();

    expect(screen.getByText(sprintf(DOCKET_SWITCH_RULING_TITLE, appellantName))).toBeInTheDocument();
    const instructionParts = DOCKET_SWITCH_RULING_INSTRUCTIONS.split("**").join("").split("\n\n");
    // The markdown formatting in COPY makes it a little tricky to automatically test the instructions
    // Including first two parts here (but there are more)
    expect(screen.getByText(instructionParts[0])).toBeInTheDocument();
    expect(screen.getByText(instructionParts[1])).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    render(<DocketSwitchRulingForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation', () => {
    it('disables submit until all fields valid', async () => {
      const context = 'Lorem ipsum';

      render(<DocketSwitchRulingForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /submit/i });

      expect(onSubmit).not.toHaveBeenCalled();

      await userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      await fillOutDocketSwitchForm(submit, context)

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);
      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });
    it('enables the submit button if context is not filled out', async () => {
      const context = 'Lorem ipsum';

      render(<DocketSwitchRulingForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /submit/i });

      expect(onSubmit).not.toHaveBeenCalled();

      await userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      await fillOutDocketSwitchForm(submit, null)

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);
      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    })
    const fillOutDocketSwitchForm = async (submit, context) => {
      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      //   Set disposition
      await userEvent.click(
        screen.getByRole('radio', { name: /grant all issues/i })
      );

      //   Set context
      await userEvent.type(
        screen.getByRole('textbox', { name: /context/i }),
        context
      );

      //   Select an attorney
      await selectEvent.select(
        screen.getByLabelText(/assign to office of the clerk of the board/i),
        clerkOfTheBoardAttorneys[1].label
      );
    }
  });

  it.skip('fires onSubmit with correct values', async () => {
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
      clerkOfTheBoardAttorneys[1].label
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
        attorney: clerkOfTheBoardAttorneys[1],
      });
    });
  });

  it('allows setting default attorney', async () => {
    render(
      <DocketSwitchRulingForm
        {...defaults}
        defaultAttorneyId={clerkOfTheBoardAttorneys[1].value}
      />
    );

    // This one
    expect(screen.queryByText(clerkOfTheBoardAttorneys[1].label)).toBeTruthy();

    // Not this one
    expect(screen.queryByText(clerkOfTheBoardAttorneys[0].label)).not.toBeTruthy();
  });
});

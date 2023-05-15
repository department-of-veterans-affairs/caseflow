import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import { BrowserRouter } from 'react-router-dom';
import { MTVJudgeDisposition } from 'app/queue/mtv/MTVJudgeDisposition';
import { amaAppeal } from 'test/data/appeals';
import { generateAttorneys } from 'test/data/user';
import { generateAmaTask } from 'test/data/tasks';

import { DISPOSITION_OPTIONS } from 'constants/MOTION_TO_VACATE';

const task = generateAmaTask({
  type: 'VacateMotionMailTask',
  instructions: ['Lorem ipsum dolor sit amet, consectetur adipiscing'],
});

describe('MTVJudgeDisposition', () => {
  const onSubmit = jest.fn();

  const defaults = {
    appeal: amaAppeal,
    attorneys: generateAttorneys(5),
    task,
    onSubmit,
  };

  const setup = (props) =>
    render(<MTVJudgeDisposition {...defaults} {...props} />, {
      wrapper: BrowserRouter,
    });

  const selectRadioField = (radioSelection) => {
    // What type of vacate?
    const radioFieldToSelect = screen.getByLabelText(radioSelection);

    userEvent.click(radioFieldToSelect);
  };

  const enterAdditionalContext = (instructions) => {
    const instructionsField = screen.getByRole(
      'textbox',
      { name: 'Provide context and instructions on which issues should be granted Optional' }
    );

    userEvent.type(instructionsField, instructions);
  };

  const selectDisposition = async (
    disposition = 'grant all',
    vacateType = 'Vacate and Readjudication (1 document)',
    hyperlink = 'www.caseflow.com',
    instructions = 'testing'
  ) => {

    userEvent.click(
      screen.getByLabelText(new RegExp(disposition, 'i'))
    );

    if ((/grant/i).test(disposition)) {
      await waitFor(() => {
        expect(
          screen.getByText(/what type of vacate/i)
        ).toBeInTheDocument();
      });

      selectRadioField(vacateType);

    } else {
      await waitFor(() => {
        expect(
          screen.getByLabelText(/insert caseflow reader document hyperlink/i)
        ).toBeInTheDocument();
      });
    }

    enterAdditionalContext(instructions);

    await userEvent.click(
      screen.getByText('Submit')
    );
  };

  describe('default view', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe.each(DISPOSITION_OPTIONS.map((item) => [item.value, item]))(
    'with %s disposition selected',
    (disposition, { displayText: label }) => {
      it('renders correctly', async () => {
        const { container } = setup();

        await selectDisposition(label);

        expect(container).toMatchSnapshot();
      });

      it('passes a11y', async () => {
        const { container } = setup();

        await selectDisposition(label);

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });
    }
  );

  describe('instructions sent', () => {
    // let vacateType = '';
    // let hyperlink = '';
    // let instructions = '';
    // let disposition = '';
    // const formatInstructions = () => {
    //   const parts = [disposition];

    //   switch (disposition) {
    //   case 'grant all':
    //   case 'partially_granted':
    //     parts.push(vacateType);
    //     parts.push(instructions);
    //     break;
    //   case 'denied':
    //   case 'dismissed':
    //     parts.push(instructions);
    //     parts.push(hyperlink);
    //     break;
    //   default:
    //     parts.push(instructions);
    //   }

    //   return parts.join('\n');
    // };
    // const handleSubmit = () => {
    //   task.instructions = formatInstructions({ disposition, vacateType, hyperlink, instructions });
    // };

    it.only('sends the correct instructions based on grant all disposition', async () => {
      const disposition = 'grant all';
      const vacateType = 'Vacate and Readjudication (1 document)';
      const instructions = 'instructions from judge';

      setup();

      await selectDisposition(
        disposition,
        vacateType,
        instructions
      );

      // disposition = 'grant all';
      // vacateType = 'vacate and de novo';
      // instructions = 'instructions from judge';
      // handleSubmit(disposition, vacateType, hyperlink, instructions);
      expect(onSubmit.mock.calls[0][0].instructions).toMatch('**Motion To Vacate:**  \n' +
        ' Grant Or Partial Vacatur\n' +
        '\n' +
        '**Type:**  \n' +
        'Vacate and Readjudication (1 document)\n' +
        '\n' +
        '**Detail:**  \n' +
        'testing\n');
    });

    it('sends the correct instructions based on partially granted disposition', () => {

      // disposition = 'partially_granted';
      // vacateType = 'straight vacate';
      // instructions = 'some instructions from judge';
      // handleSubmit(disposition, vacateType, hyperlink, instructions);
      expect(task.instructions).toMatch('partially_granted\nstraight vacate\nsome instructions from judge');
    });

    it('sends the correct instructions based on denied disposition', () => {

      // disposition = 'denied';
      // instructions = 'instructions from judge';
      // hyperlink = 'www.caseflow.com';
      // handleSubmit(disposition, vacateType, hyperlink, instructions);
      expect(task.instructions).toMatch('denied\ninstructions from judge\nwww.caseflow.com');
    });

    it('sends the correct instructions based on dismissed disposition', () => {

      // disposition = 'dismissed';
      // instructions = 'new instructions from judge';
      // hyperlink = 'www.google.com';
      // handleSubmit(disposition, vacateType, hyperlink, instructions);
      expect(task.instructions).toMatch('dismissed\nnew instructions from judge\nwww.google.com');
    });
  });
});

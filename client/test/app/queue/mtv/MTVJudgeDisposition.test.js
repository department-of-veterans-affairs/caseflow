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

let linkField = /Insert Caseflow Reader document hyperlink to/;
let instructionsField = /Provide context and instructions on which issues should be/;

const selectRadioField = (radioSelection) => {
  const radioFieldToSelect = screen.getByLabelText(radioSelection);

  userEvent.click(radioFieldToSelect);
};

const enterAdditionalContext = (text, selectedField) => {
  const textField = screen.getByText(selectedField);

  userEvent.type(textField, text);
};

const selectDisposition = async (disposition = 'grant all') => {
  userEvent.click(
    screen.getByLabelText(new RegExp(disposition, 'i'))
  );

  if ((/grant/i).test(disposition)) {
    await waitFor(() => {
      expect(
        screen.getByText(/what type of vacate/i)
      ).toBeInTheDocument();
    });
  } else {
    await waitFor(() => {
      expect(
        screen.getByLabelText(/insert caseflow reader document hyperlink/i)
      ).toBeInTheDocument();
    });
  }
};

const fillForm = async (disposition, vacateType, vacateIssues, hyperlink, instructions) => {
  userEvent.click(
    screen.getByLabelText(new RegExp(disposition, 'i'))
  );

  if ((/grant all/i).test(disposition)) {
    await waitFor(() => {
      expect(
        screen.getByText(/what type of vacate/i)
      ).toBeInTheDocument();
    });

    selectRadioField(vacateType);

  } else if ((/grant partial/i).test(disposition)) {
    await waitFor(() => {
      expect(
        screen.getByText(/which issues would you like to vacate/i)
      ).toBeInTheDocument();
    });

    selectRadioField(vacateType);
    selectRadioField(vacateIssues);

  } else {
    await waitFor(() => {
      expect(
        screen.getByLabelText(/insert caseflow reader document hyperlink/i)
      ).toBeInTheDocument();
    });

    enterAdditionalContext(hyperlink, linkField);

  }

  enterAdditionalContext(instructions, instructionsField);

  await userEvent.click(
    screen.getByText('Submit')
  );
};

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
    ({ displayText: label }) => {
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

  describe('Case timeline instructions', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    describe('grant or partial grant instructions sent', () => {
      it('sends the correct instructions based on grant all disposition', async () => {
        const disposition = 'grant all';
        const vacateType = 'Vacate and De Novo (2 documents)';
        let vacateIssues;
        let hyperlink;
        const instructions = 'instructions from judge';

        setup();

        await fillForm(
          disposition,
          vacateType,
          vacateIssues,
          hyperlink,
          instructions
        );

        expect(onSubmit.mock.calls[0][0].instructions).toMatch('**Motion To Vacate:**  ' +
          '\nGrant Or Partial Vacatur' +
          '\n' +
          '\n**Type:**  ' +
          '\nVacate and De Novo (2 documents)' +
          '\n' +
          '\n**Detail:**  ' +
          '\ninstructions from judge' +
          '\n'
        );
      });

      it('sends the correct instructions based on partially granted disposition', async () => {
        const disposition = 'Grant partial vacatur';
        const vacateType = 'Straight Vacate (1 document)';
        const vacateIssues = '1. This is a description of the decision';
        let hyperlink;
        const instructions = 'some instructions from judge';

        setup();

        await fillForm(
          disposition,
          vacateType,
          vacateIssues,
          hyperlink,
          instructions
        );

        expect(onSubmit.mock.calls[0][0].instructions).toMatch('**Motion To Vacate:**  ' +
          '\nPartial Vacatur' +
          '\n' +
          '\n**Type:**  ' +
          '\nStraight Vacate (1 document)' +
          '\n' +
          '\n**Detail:**  ' +
          '\nsome instructions from judge' +
          '\n'
        );
      });
    });

    describe('deny or dismiss instructions sent', () => {
      it('sends the correct instructions based on denied disposition', async () => {
        const disposition = 'deny';
        let vacateType;
        let vacateIssues;
        const hyperlink = 'www.caseflow.com';
        const instructions = 'testing';

        setup();

        await fillForm(
          disposition,
          vacateType,
          vacateIssues,
          hyperlink,
          instructions
        );

        expect(onSubmit.mock.calls[0][0].instructions).toMatch(
          '**Motion To Vacate:**  \n' +
          'Denial Of All Issues For Vacatur\n\n' +
          '**Detail:**  \ntesting\n\n' +
          '**Hyperlink:**  \nwww.caseflow.com\n'
        );
      });

      it('sends the correct instructions based on dismissed disposition', async () => {
        const disposition = 'dismiss';
        let vacateType;
        let vacateIssues;
        const hyperlink = 'www.google.com';
        const instructions = 'new instructions from judge';

        setup();

        await fillForm(
          disposition,
          vacateType,
          vacateIssues,
          hyperlink,
          instructions
        );

        expect(onSubmit.mock.calls[0][0].instructions).toMatch(
          '**Motion To Vacate:**  \n' +
          'Dismissal\n\n**Detail:**  \nnew instructions from judge\n\n' +
          '**Hyperlink:**  \nwww.google.com\n'
        );
      });
    });
  });
});

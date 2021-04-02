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

  const selectDisposition = async (disposition = 'grant all') => {
    await userEvent.click(
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
});

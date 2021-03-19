import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import { BrowserRouter } from 'react-router-dom';
import { MTVJudgeDisposition } from 'app/queue/mtv/MTVJudgeDisposition';
import { amaAppeal } from 'test/data/appeals';
import { generateAttorneys } from 'test/data/user';
import { generateAmaTask } from '../../../data/tasks';

// import { tasks, attorneys, appeals } from './sample';
const task = generateAmaTask({
  type: 'VacateMotionMailTask',
  instructions: ['Lorem ipsum dolor sit amet, consectetur adipiscing']
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

  describe('default view', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
      // expect(
      //   screen.getByText(JUDGE_ADDRESS_MTV_TITLE)
      // ).toBeInTheDocument();

      // expect(
      //   screen.getByText(DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B)
      // ).toBeInTheDocument();

      // expect(
      //   screen.getByText(
      //     [
      //       'You are switching from Direct Review to Hearing.',
      //       'Tasks specific to the Direct Review docket will be automatically removed,',
      //       'and tasks associated with the Hearing docket will be automatically created.',
      //     ].join(' ')
      //   )
      // ).toBeInTheDocument();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });
});

import React from 'react';
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from '@testing-library/react';

import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';

import COPY from 'app/../COPY';
import { EditCavcRemandForm } from 'app/queue/cavc/EditCavcRemandForm';

import {
  existingValues,
  decisionIssues,
  supportedDecisionTypes,
  supportedRemandTypes,
} from 'test/data/queue/cavc';

const getDecisionGroup = () => {
  return screen.getByRole('group', { name: /how are you proceeding/i });
};
const fillDocketNumber = async () => {
  await userEvent.type(
    screen.getByRole('textbox', { name: /court docket number/i }),
    existingValues.docketNumber
  );
};
const fillAttorney = async () => {
  const radioGroup = screen.getByRole('group', {
    name: /represented by an attorney/i,
  });

  await userEvent.click(
    within(radioGroup).getByRole('radio', { name: /yes/i })
  );
};
const fillJudge = async () => {
  await selectEvent.select(screen.getByLabelText(/cavc judge's name/i), [
    existingValues.judge,
  ]);
};
const fillDecisionDate = async () => {
  await fireEvent.change(screen.getByLabelText(/decision date/i), {
    target: { value: existingValues.decisionDate },
  });
};
const fillInstructions = async () => {
  await userEvent.type(
    screen.getByRole('textbox', { name: /instructions/i }),
    existingValues.instructions
  );
};
const fillStatic = async () => {
  await fillDocketNumber();
  await fillAttorney();
  await fillJudge();
  await fillDecisionDate();
  await fillInstructions();
};

describe('EditCavcRemandForm', () => {
  const onCancel = jest.fn();
  const onSubmit = jest.fn();
  const defaults = {
    decisionIssues,
    supportedDecisionTypes,
    supportedRemandTypes,
    onCancel,
    onSubmit,
  };

  const setup = (props) =>
    render(<EditCavcRemandForm {...defaults} {...props} />);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('adding new', () => {
    describe('all feature toggles enabled', () => {
      it('renders correctly', () => {
        const { container } = setup();

        expect(container).toMatchSnapshot();
        expect(screen.getByText(COPY.ADD_CAVC_PAGE_TITLE)).toBeInTheDocument();
      });

      it.only('passes a11y testing', async () => {
        const { container } = setup();

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });
    });

    it('fires onCancel', () => {
      setup();
      expect(onCancel).not.toHaveBeenCalled();

      userEvent.click(screen.getByRole('button', { name: /cancel/i }));
      expect(onCancel).toHaveBeenCalled();
    });

    describe('with Remand decision', () => {
      it.each(['jmr', 'jmpr', 'mdr'])(
        'renders correctly with %s remand type selected',
        async (remandType) => {
          const { container } = setup();

          await fillStatic();

          await userEvent.click(
            within(getDecisionGroup()).getByRole('radio', { name: /remand/i })
          );

          await waitFor(() => {
            expect(
              screen.getByRole('group', {
                name: /what type of remand is this/i,
              })
            ).toBeInTheDocument();
          });

          await userEvent.click(
            screen.getByRole('radio', { name: new RegExp(remandType, 'i') })
          );

          if (remandType === 'mdr') {
            expect(
              await screen.findByText(/choosing mdr will/i)
            ).toBeInTheDocument();
          }

          expect(container).toMatchSnapshot();
        }
      );
    });

    describe('with Reversal decision', () => {
      it.each(['yes', 'no'])(
        'renders correctly when judgement/mandate dates provided set to %s',
        async (remandDatesProvided) => {
          const { container } = setup();

          await fillStatic();

          await userEvent.click(
            within(getDecisionGroup()).getByRole('radio', { name: /reversal/i })
          );

          const datesProvidedGroup = await screen.findByRole('group', {
            name: /judgement and mandate dates provided/i,
          });

          await userEvent.click(
            within(datesProvidedGroup).getByRole('radio', {
              name: new RegExp(remandDatesProvided, 'i'),
            })
          );

          if (remandDatesProvided === 'yes') {
            expect(
              await screen.findByText(/same as court's decision date/i)
            ).toBeInTheDocument();
          } else {
            expect(
              await screen.findByText(
                /this task will be put on hold for 90 days/i
              )
            ).toBeInTheDocument();
          }

          expect(container).toMatchSnapshot();
        }
      );
    });
  });

  describe('editing existing', () => {
    describe('all feature toggles enabled', () => {
      it('renders correctly', () => {
        const { container } = setup({ existingValues });

        expect(container).toMatchSnapshot();
        expect(screen.getByText(COPY.EDIT_CAVC_PAGE_TITLE)).toBeInTheDocument();
      });

      it('passes a11y testing', async () => {
        const { container } = setup({ existingValues });

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });
    });

    it('fires onCancel', () => {
      setup({ existingValues });
      expect(onCancel).not.toHaveBeenCalled();

      userEvent.click(screen.getByRole('button', { name: /cancel/i }));
      expect(onCancel).toHaveBeenCalled();
    });
  });
});

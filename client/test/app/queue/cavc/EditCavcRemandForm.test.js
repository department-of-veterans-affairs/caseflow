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
import { format, sub } from 'date-fns';

import {
  existingValues,
  existingValuesJmr,
  decisionIssues,
  supportedDecisionTypes,
  supportedRemandTypes,
} from 'test/data/queue/cavc';

const fillDecisionType = () => {
  //return screen.getByRole('group', { name: /how are you proceeding/i });
    screen.getByText(/how are you proceeding\?/i),
    existingValues.decisionType
};

const fillRemandType = async() => {
  await userEvent.type(
    screen.getByText(/what type of remand is this\?/i),
    existingValues.remandType
  );
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
  //fillDecisionType();
  //fillRemandType();
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

//     describe('with Remand decision', () => {
//       it.each(['jmr', 'jmpr', 'mdr'])(
//         'renders correctly with %s remand type selected',
//         async (remandType) => {
//           const { container } = setup();

//           await fillStatic();

//           const { decisionType } = 'Remand';

//           expect(await screen.findByText(/how are you proceeding\?/i)).toBeInTheDocument();
//           expect(await screen.findByText(/what type of remand is this\?/i)).toBeInTheDocument();

//           if (remandType === 'mdr') {
//             expect(screen.findByText(/choosing mdr will/i)).toBeInTheDocument();
//           }

//           expect(container).toMatchSnapshot();
//         }
//       );
// //     });

//     describe('with Reversal decision', () => {
//       it.each(['yes', 'no'])(
//         'renders correctly when judgement/mandate dates provided set to %s',
//         async (remandDatesProvided) => {
//           const { container } = setup();

//           await fillStatic();

//           await userEvent.click(
//             within(getDecisionGroup()).getByRole('radio', { name: /reversal/i })
//           );

//           const datesProvidedGroup = await screen.findByRole('group', {
//             name: /judgement and mandate dates provided/i,
//           });

//           await userEvent.click(
//             within(datesProvidedGroup).getByRole('radio', {
//               name: new RegExp(remandDatesProvided, 'i'),
//             })
//           );

//           if (remandDatesProvided === 'yes') {
//             expect(
//               await screen.findByText(/same as court's decision date/i)
//             ).toBeInTheDocument();
//           } else {
//             expect(
//               await screen.findByText(
//                 /this task will be put on hold for 90 days/i
//               )
//             ).toBeInTheDocument();
//           }

//           expect(container).toMatchSnapshot();
//         }
//       );
//     });
//   });

  describe('editing existing', () => {
    describe('all feature toggles enabled', () => {
      it('renders correctly', () => {
        const { container } = setup({ existingValues });

        expect(container).toMatchSnapshot();
        expect(screen.getByText(COPY.EDIT_CAVC_PAGE_TITLE)).toBeInTheDocument();
      });

      it('fires onCancel', () => {
        setup({ existingValues });
        expect(onCancel).not.toHaveBeenCalled();
  
        userEvent.click(screen.getByRole('button', { name: /cancel/i }));
        expect(onCancel).toHaveBeenCalled();
      });
    });

    describe('with remand decision', () => {
      it('renders expected fields that are the same for all types', () => {
        const { container } = setup({ existingValues });

        expect(screen.getByRole('textbox', { name: /what is the court docket number\?/i })).toBeInTheDocument();
        expect(screen.getByText(/was the appellant represented by an attorney\?/i)).toBeInTheDocument();

        const group = screen.getByRole('group', { name: /was the appellant represented by an attorney\?/i });
        within(group).getByText(/yes/i);
        within(group).getByText(/no/i);

        expect(screen.getByText(/what is the cavc judge's name\?/i)).toBeInTheDocument();
        expect(screen.getByRole('textbox', { name: /how are you proceeding\?/i })).toBeInTheDocument();

        //existingValues.decisionType = remand, so there should be a remand textboxt in the document
        expect(screen.getByRole('textbox', { name: /what type of remand is this\? remandtype/i
                })).toBeInTheDocument();
        
        expect(screen.getByLabelText(/what is the court's decision date\?/i)).toBeInTheDocument();

        //issues section
        expect(screen.getByText(/which issues are being addressed by the court\?/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /unselect all/i })).toBeInTheDocument();
        expect(screen.getByText(/please unselect any tasks you would like to remove:/i)).toBeInTheDocument();
        expect(screen.getByRole('textbox', { name: /provide context and instructions for this action/i
          })).toBeInTheDocument();

        expect(container).toMatchSnapshot();
      });

      it('renders expected fields for mdr remandType', () => {
        const { container } = setup({ existingValues });

        expect(screen.queryByLabelText(/what is the court's judgement date\?/i)).not.toBeInTheDocument();
        expect(screen.queryByLabelText(/what is the court's mandate date\?/i)).not.toBeInTheDocument();

        //expect(screen.findByText(/choosing mdr will/i)).toBeInTheDocument();

        //expect(screen.findByText(federalcircuit question)).toBeInTheDocument();

        expect(container).toMatchSnapshot();
      });

      it('renders expected fields for jmr remandType', () => {
        const { container } = setup( {existingValuesJmr} );
        existingValues.remandType = 'jmr';
        existingValues.judgementDate = format(sub(new Date(), { days: 6 }), 'yyyy-MM-dd');
        existingValues.mandateDate = format(sub(new Date(), { days: 6 }), 'yyyy-MM-dd');

        expect(screen.queryByLabelText(/what is the court's judgement date\?/i)).toBeInTheDocument();
        expect(screen.queryByLabelText(/what is the court's mandate date\?/i)).toBeInTheDocument();

        expect(container).toMatchSnapshot();
      });
    });
  });
});
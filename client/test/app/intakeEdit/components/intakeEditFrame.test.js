import React from 'react';
import { screen, render } from '@testing-library/react';
import ReduxBase from 'app/components/ReduxBase';
import IntakeEditFrame from 'app/intakeEdit/IntakeEditFrame';
import { intakeEditReducer, mapDataToInitialState } from 'app/intakeEdit/reducers';
import { testProps } from '../testProps';
import COPY from 'app/../COPY';

const renderIntakeEditFrame = (props) => {
  const initialState = mapDataToInitialState(props);

  return render(
    <ReduxBase initialState={initialState} reducer={intakeEditReducer}>
      <IntakeEditFrame {...props} />
    </ReduxBase>
  );
};

describe('IntakeEditFrame', () => {
  let props;

  beforeEach(() => {
    window.analyticsPageView = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('With the removeCompAndPen feature toggle', () => {
    beforeEach(() => {
      props = testProps();
    });

    describe('turned on and with a benefit type of compensation', () => {
      it('displays the edit disabled banner', () => {
        props.featureToggles = {
          removeCompAndPenIntake: true
        };
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_REMOVE_COMP_AND_PEN)).toBeInTheDocument();
      });
    });

    describe('turned on and with a benefit type not compensation or pension', () => {
      it('does NOT display the edit disabledbanner', () => {
        props.featureToggles = {
          removeCompAndPenIntake: true
        };
        props.serverIntake.benefitType = 'fiduciary';
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_REMOVE_COMP_AND_PEN)).not.toBeInTheDocument();
      });
    });

    describe('turned off and with a benefit type of compensation', () => {
      it('does NOT display the edit disabled banner', () => {
        props.featureToggles = {
          removeCompAndPenIntake: false
        };
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_REMOVE_COMP_AND_PEN)).not.toBeInTheDocument();
      });
    });
  });
});

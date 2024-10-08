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

  describe('With the removeCompAndPen feature toggle turned on', () => {
    beforeEach(() => {
      props = testProps();
      props.featureToggles = {
        removeCompAndPenIntake: true
      };
    });

    describe('and with a benefit type of compensation', () => {
      it('displays the edit disabled banner', () => {
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN)).toBeInTheDocument();
      });
    });

    describe('and with a benefit type of pension', () => {
      it('displays the edit disabled banner', () => {
        props.serverIntake.benefitType = 'pension';
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN)).toBeInTheDocument();
      });
    });

    describe('and with a benefit type not compensation or pension', () => {
      it('does NOT display the edit disabledbanner', () => {
        props.serverIntake.benefitType = 'fiduciary';
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN)).not.toBeInTheDocument();
      });
    });
  });

  describe('With the removeCompAndPen feature toggle turned off', () => {
    beforeEach(() => {
      props = testProps();
      props.featureToggles = {
        removeCompAndPenIntake: false
      };
    });

    describe('and with a benefit type of compensation', () => {
      it('does NOT display the edit disabled banner', () => {
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN)).not.toBeInTheDocument();
      });
    });

    describe('and with a benefit type of pension', () => {
      it('does NOT display the edit disabled banner', () => {
        props.serverIntake.benefitType = 'pension';
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN)).not.toBeInTheDocument();
      });
    });

    describe('and with a benefit type not compensation or pension', () => {
      it('does NOT display the edit disabled banner', () => {
        props.serverIntake.benefitType = 'fiduciary';
        renderIntakeEditFrame(props);

        expect(screen.queryByText(COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN)).not.toBeInTheDocument();
      });
    });
  });
});

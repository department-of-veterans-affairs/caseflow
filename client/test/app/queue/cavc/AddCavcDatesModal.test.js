import React from 'react';
import moment from 'moment';
import { render, fireEvent, screen } from '@testing-library/react';
import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';
import AddCavcDatesModal from 'app/queue/cavc/AddCavcDatesModal';
import COPY from 'COPY';
import * as uiActions from 'app/queue/uiReducer/uiActions';

describe('AddCavcDatesModal', () => {
  const appealId = amaAppeal.externalId;

  const setup = (props) => {
    return render(
      <AddCavcDatesModal
      appealId={appealId}
      {...props}
      />,
      {
        wrapper: queueWrapper
      });
    }

    const clickSubmit = () => {
      const submitButton = screen.getByRole('button', { name: 'Submit' });
      fireEvent.click(submitButton);
    }

  it('renders correctly', () => {
    const {asFragment} = setup();
    expect(asFragment()).toMatchSnapshot();
  });

  it('submits successfully', async () => {
    const {asFragment} = setup();
    jest.spyOn(uiActions, 'requestPatch').mockImplementation(() => async (dispatch) => {
      return Promise.resolve();
    });
    const judgementDate = '2020-03-27'
    const mandateDate = '2019-03-31'
    const instructions = 'test instructions';

    const judgementDateElement = screen.getByLabelText(/What is the Court's judgement date?/i);
    expect(judgementDateElement).toBeInTheDocument();
    fireEvent.change(judgementDateElement, { target: { value: judgementDate } });

    const mandateDateElement = screen.getByLabelText(/What is the Court's mandate date?/i);
    expect(mandateDateElement).toBeInTheDocument();
    fireEvent.change(mandateDateElement, { target: { value: mandateDate } });

    const instructionsElement = screen.getByLabelText(/Provide instructions and context for this action/i);
    expect(instructionsElement).toBeInTheDocument();
    fireEvent.change(instructionsElement, { target: { value: instructions } });

    const submitButton = screen.getByRole('button', { name: 'Submit' });
    fireEvent.click(submitButton);

    expect(asFragment()).toMatchSnapshot();
  });

  describe('form validations', () => {
    const futureDate = moment(new Date().toISOString()).add(2, 'day').format('YYYY-MM-DD');
    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const submitButton = screen.getByRole('button', { name: 'Submit' });
        fireEvent.click(submitButton);

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on future date selection', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const judgementDateElement = screen.getByLabelText(/What is the Court's judgement date?/i);
        fireEvent.change(judgementDateElement, { target: { value: futureDate } });

        clickSubmit();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected date', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const judgementDateElement = screen.getByLabelText(/What is the Court's judgement date?/i);
        fireEvent.change(judgementDateElement, { target: { value: '2020-11-11' } });

        clickSubmit();

        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });

    describe('mandate date validations', () => {
      const error = COPY.CAVC_MANDATE_DATE_ERROR;

      it('shows error on no selected date', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        clickSubmit();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on future date selection', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const mandateDateElement = screen.getByLabelText(/What is the Court's mandate date?/i);
        fireEvent.change(mandateDateElement, { target: { value: futureDate } });

        clickSubmit();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected date', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const mandateDateElement = screen.getByLabelText(/What is the Court's mandate date?/i);
        fireEvent.change(mandateDateElement, { target: { value: '2020-11-11' } });

        clickSubmit();

        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });

    describe('cavc dates instructions validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on empty instructions', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const instructionsElement = screen.getByLabelText(/Provide instructions and context for this action/i);
        fireEvent.change(instructionsElement, { target: { value: '' } });

        clickSubmit();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on instructions', () => {
        setup();
        expect(screen.queryByText(error)).not.toBeInTheDocument();

        const instructionsElement = screen.getByLabelText(/Provide instructions and context for this action/i);
        fireEvent.change(instructionsElement, { target: { value: '2020-11-11' } });

        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });
  });
});

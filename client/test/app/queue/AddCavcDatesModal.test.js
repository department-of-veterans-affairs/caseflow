import React from 'react';
import { mount } from 'enzyme';
import moment from 'moment';

import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcDatesModal from 'app/queue/AddCavcDatesModal';
import COPY from 'COPY';

import * as uiActions from 'app/queue/uiReducer/uiActions';

describe('AddCavcDatesModal', () => {

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const appealId = amaAppeal.externalId;

  const setup = ({ appealId: id }) => {
    return mount(
      <AddCavcDatesModal appealId={id} />,
      {
        wrappingComponent: queueWrapper,
      });
  };

  const clickSubmit = (cavcModal) => cavcModal.find('button#Add-Court-dates-button-id-1').simulate('click');

  it('renders correctly', async () => {
    const cavcModal = setup({ appealId });

    expect(cavcModal).toMatchSnapshot();
  });

  it('submits succesfully', async () => {
    jest.spyOn(uiActions, 'requestPatch').mockImplementation(() => new Promise((resolve) => resolve()));

    const cavcModal = setup({ appealId });

    const judgementDate = '03/27/2020';
    const mandateDate = '03/31/2019';
    const instructions = 'test instructions';

    cavcModal.find({ name: 'judgement-date' }).find('input').
      simulate('change', { target: { value: judgementDate } });

    cavcModal.find({ name: 'mandate-date' }).find('input').
      simulate('change', { target: { value: mandateDate } });

    cavcModal.find({ name: 'context-and-instructions-textBox' }).
      find('textarea').
      simulate('change', { target: { value: instructions } });

    clickSubmit(cavcModal);

    expect(uiActions.requestPatch).toHaveBeenCalledWith(`/appeals/${appealId}/cavc_remand`, {
      data: {
        judgement_date: judgementDate,
        mandate_date: mandateDate,
        remand_appeal_id: appealId,
        instructions,
        source_form: 'add_cavc_dates_modal',
      }
    }, {
      title: COPY.CAVC_REMAND_CREATED_TITLE,
      detail: COPY.CAVC_REMAND_CREATED_DETAIL
    });
    expect(cavcModal).toMatchSnapshot();
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';
    const futureDate = moment(new Date().toISOString()).add(2, 'day').format('YYYY-MM-DD');

    const validationErrorShows = (cavcModal, errorMessage) => {
      clickSubmit(cavcModal);

      return cavcModal.find(errorClass).findWhere((node) => node.props().children === errorMessage).length > 0;
    };

    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcModal = setup({ appealId });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('shows error on future date selection', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#judgement-date').simulate('change', { target: { value: futureDate } });
        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#judgement-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('mandate date validations', () => {
      const error = COPY.CAVC_MANDATE_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcModal = setup({ appealId });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('shows error on future date selection', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#mandate-date').simulate('change', { target: { value: futureDate } });
        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#mandate-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('cavc dates instructions validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on empty instructions', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#context-and-instructions-textBox').simulate('change', { target: { value: '' } });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on instructions', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#context-and-instructions-textBox').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });
  });
});

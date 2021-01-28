import React from 'react';
import { mount } from 'enzyme';

import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcDatesModal from 'app/queue/AddCavcDatesModal';
import COPY from 'COPY';

describe('AddCavcDatesModal', () => {
  beforeEach(() => jest.clearAllMocks());

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

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';

    const validationErrorShows = (cavcModal, errorMessage) => {
      // component.find('#Add-Court-dates-button-id-1').simulate('click');
      clickSubmit(cavcModal);

      return cavcModal.find(errorClass).findWhere((node) => node.props().children === errorMessage).length > 0;
    };

    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcModal = setup({ appealId });

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

      it('does not show error on selected date', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#mandate-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('text instructions validations', () => {
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

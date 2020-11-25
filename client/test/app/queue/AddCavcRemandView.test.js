import React from 'react';
import { mount } from 'enzyme';

import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcRemandView from 'app/queue/AddCavcRemandView';

import COPY from 'COPY';

describe('AddCavcRemandView', () => {
  beforeEach(() => jest.clearAllMocks());

  const appealId = amaAppeal.externalId;

  const setup = (props = { appealId }) => {
    return mount(
      <AddCavcRemandView appealId={props.appealId} />,
      {
        wrappingComponent: queueWrapper
      });
  };

  it('renders correctly', async () => {
    const cavcForm = setup({ appealId });

    expect(cavcForm).toMatchSnapshot();
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';

    const validationErrorShows = (component, errorMessage) => {
      component.find('#button-next-button').simulate('click');

      return component.find(errorClass).findWhere((node) => node.props().children === errorMessage).length > 0;
    };

    describe('docket number validations', () => {
      const error = COPY.CAVC_DOCKET_NUMBER_ERROR;

      it('shows error on blank docket number', () => {
        const cavcForm = setup({ appealId });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('shows error on incorrectly formatted docket number', () => {
        const cavcForm = setup({ appealId });

        cavcForm.find('#docket-number').simulate('change', { target: { value: 'bad docket number' } });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });
    });
  });

  // describe('deselecting "remand" hides remand subtypes', () => {});
  // describe('all issues are selected on page load', () => {});
});

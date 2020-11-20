import React from 'react';
import { mount } from 'enzyme';

import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcRemandView from 'app/queue/AddCavcRemandView';

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

  // TODO: break out testing from feature test
  // describe('form validations', () => {});
  // describe('deselecting "remand" hides remand subtypes', () => {});
});

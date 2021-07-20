import React from 'react';
import { mount } from 'enzyme';

import EditAppellantInformation from 'app/queue/editAppellantInformation/EditAppellantInformation';
import { queueWrapper } from 'test/data/stores/queueStore';

import { amaAppeal } from '../../../data/appeals';

describe('EditAppellantInformation', () => {
  const setup = () => {
    return mount(<EditAppellantInformation appealId={amaAppeal.externalId} />,
      {
        wrappingComponent: queueWrapper,
      });
  };

  it('renders default state correctly', () => {
    const container = setup();

    expect(container).toMatchSnapshot()
  });
});

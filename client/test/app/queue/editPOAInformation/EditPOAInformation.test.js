import React from 'react';
import { mount } from 'enzyme';

import EditPOAInformation from 'app/queue/editPOAInformation/EditPOAInformation';
import { amaAppeal } from '../../../data/appeals';
import { queueWrapper } from 'test/data/stores/queueStore';

describe('EditPOAInformation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = () => mount(<EditPOAInformation appealId={amaAppeal.externalId} />,
    {
      wrappingComponent: queueWrapper,
    });

  it('renders default state correctly', () => {
    const container = setup();

    expect(container).toMatchSnapshot();
  });
});

import React from 'react';
import { axe } from 'jest-axe';
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

  it('passes a11y testing', async () => {
    const container = setup();

    const results = await axe(container.html());

    expect(results).toHaveNoViolations();
  });
});

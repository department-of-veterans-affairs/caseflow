import React from 'react';
import { mount } from 'enzyme';
import {
  render,
} from '@testing-library/react';
import EditPOAInformation from 'app/queue/EditPOAInformation/EditPOAInformation';
import { queueWrapper } from 'test/data/stores/queueStore';

import { amaAppeal } from '../../../data/appeals';

describe('EditPOAInformation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = () => {
    return mount(<EditPOAInformation appealId={amaAppeal.externalId} />,
      {
        wrappingComponent: queueWrapper,
      });
  };

  it('renders default state correctly', () => {
    const container = setup();

    expect(container).toMatchSnapshot();
  });

  // it('passes a11y testing', async () => {
  //   const { container } = setup();

  //   const results = await axe(container);

  //   expect(results).toHaveNoViolations();
  // });
});

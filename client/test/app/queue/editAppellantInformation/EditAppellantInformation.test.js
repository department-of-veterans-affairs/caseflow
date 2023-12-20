import React from 'react';

import EditAppellantInformation from 'app/queue/editAppellantInformation/EditAppellantInformation';
import { queueWrapper } from 'test/data/stores/queueStore';

import { amaAppeal } from '../../../data/appeals';
import { render } from '@testing-library/react';

describe('EditAppellantInformation', () => {
  const setup = () => {
    return render(<EditAppellantInformation appealId={amaAppeal.externalId} />,
      {
        wrapper: queueWrapper,
      });
  };

  it('renders default state correctly', () => {
    const container = setup();

    expect(container).toMatchSnapshot();
  });
});

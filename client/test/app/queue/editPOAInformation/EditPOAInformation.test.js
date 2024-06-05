import React from 'react';
import { render } from '@testing-library/react';

import EditPOAInformation from 'app/queue/editPOAInformation/EditPOAInformation';
import { amaAppeal } from '../../../data/appeals';
import { queueWrapper as Wrapper } from 'test/data/stores/queueStore';

describe('EditPOAInformation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = () => {
    return render(
      <Wrapper>
        <EditPOAInformation appealId={amaAppeal.externalId} />,
      </Wrapper>
    )
  }

  it('renders default state correctly', () => {
    const container = setup();

    expect(container).toMatchSnapshot();
  });
});

import React from 'react';

import { Dot } from 'app/components/Dot';
import { render } from '@testing-library/react';

describe('Dot', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const dot = render(
      <Dot />
    );

    expect(dot.container.querySelector('span')).toHaveTextContent('·');
    expect(dot).toMatchSnapshot();
  });
});

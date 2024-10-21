import React from 'react';
import { render, screen } from '@testing-library/react';

import { ReadOnly } from 'app/hearings/components/details/ReadOnly';

describe('ReadOnly', () => {
  test('Matches snapshot with default props', () => {
    // Setup the test
    const example = 'Something\n\tElse';
    const label = 'example';

    // Run the test
    const { asFragment } = render(
      <ReadOnly label={label} text={example} />
    );

        // Assertions
        const labelElement = screen.getByText(label);
        expect(labelElement).toBeInTheDocument();

        const strongElement = screen.getByText(label, { selector: 'strong' });
        expect(strongElement).toBeInTheDocument();

        const textElement = screen.getByText(/Something\s+Else/);
        expect(textElement).toBeInTheDocument();

        expect(asFragment()).toMatchSnapshot();
  });
});

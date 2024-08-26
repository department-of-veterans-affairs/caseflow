import React from 'react';
import { render } from '@testing-library/react';

import { HelperText } from 'app/hearings/components/VirtualHearings/HelperText';

const label = 'Something helpful';

describe('HelperText', () => {
  test('Matches snapshot with default props', () => {
    // Render the component
    const { getByText, asFragment } = render(<HelperText label={label} />);

    // Assertions
    expect(getByText(label)).toBeInTheDocument();
    expect(getByText(label)).toHaveClass('helper-text');
    expect(asFragment()).toMatchSnapshot();
  });
});


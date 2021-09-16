import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import PdfUI from './PdfUI';

describe('PdfUI', () => {
  const defaultProps = {};
  const setup = (props) => {
    return render(<PdfUI {...defaultProps} {...props} />);
  };

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});

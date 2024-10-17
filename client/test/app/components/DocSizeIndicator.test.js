import React from 'react';
import { render } from '@testing-library/react';
import DocSizeIndicator from '../../../app/reader/DocSizeIndicator';

it('shows file size', () => {
  const { container } = render(<DocSizeIndicator docSize="1024" />);

  expect(container).toHaveTextContent('1.02 kB');
});

it('handles empty strings', () => {
  const { container } = render(<DocSizeIndicator docSize="" />);

  expect(container).toHaveTextContent('0 B');
});

import React from 'react';
import { render, screen } from '@testing-library/react';
import DocSizeIndicator from '../../../app/reader/DocSizeIndicator';

it('shows file size', () => {
  const { container } = render(<DocSizeIndicator docSize="1024" />);

  expect(container).toHaveTextContent('1.02 kB');
});

it('handles empty strings', () => {
  const { container } = render(<DocSizeIndicator docSize="" />);

  expect(container).toHaveTextContent('0 B');
});
it('handles null', () => {
  const { container } = render(<DocSizeIndicator docSize={null} />);

  expect(container).toHaveTextContent('0 B');
});
it('shows a file size warning when file size is large', () => {
  const connectionSpeed = 1;
  const downloadSpeedInBytes = connectionSpeed * 125000;
  const fileSize = downloadSpeedInBytes * 16;

  render(<DocSizeIndicator docSize={fileSize} browserSpeedInBytes={downloadSpeedInBytes} />);
  expect(screen.getByTitle('Large File Warning')).toBeInTheDocument();
});

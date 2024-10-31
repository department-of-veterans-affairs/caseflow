import React from 'react';
import { render } from '@testing-library/react';
import DocSizeIndicator from '../../../app/reader/DocSizeIndicator';

it('shows file size', () => {
  const { container } = render(<DocSizeIndicator docSize="1024" />);

  expect(container).toHaveTextContent('1 kB');
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

  const { getByTitle } = render(<DocSizeIndicator docSize={fileSize} browserSpeedInBytes={downloadSpeedInBytes} />);

  expect(getByTitle('Large File Warning')).toBeInTheDocument();
});
it('does not show a file size warning when file size is not large', () => {
  const connectionSpeed = 1;
  const downloadSpeedInBytes = connectionSpeed * 125000;
  const fileSize = downloadSpeedInBytes * 15;

  const { queryByTitle } = render(<DocSizeIndicator docSize={fileSize} browserSpeedInBytes={downloadSpeedInBytes} />);

  expect(queryByTitle('Large File Warning')).not.toBeInTheDocument();
});

import React from 'react';
import { EditNODModal } from 'app/queue/components/EditNODModal';
import { fireEvent, render, screen } from '@testing-library/react';

describe('EditNODModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const testNODDate = '2020-10-31';

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(
      <EditNODModal
        onCancel={onCancel}
        onSubmit={onSubmit}
        nodDate={testNODDate}
      />
    );

    expect(container).toMatchSnapshot();
  });

  it('should fire cancel event', () => {
    render(
      <EditNODModal
        onCancel={onCancel}
        onSubmit={onSubmit}
        nodDate={testNODDate}
      />
    );

    fireEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  it('should submit event', () => {
    render(
      <EditNODModal
        onCancel={onCancel}
        onSubmit={onSubmit}
        nodDate={testNODDate}
      />
    );

    fireEvent.click(screen.getByText('Submit'));
    expect(onSubmit).toHaveBeenCalled();
  });
});

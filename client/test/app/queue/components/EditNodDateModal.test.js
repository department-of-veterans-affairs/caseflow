import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';

  const setupEditNodDateModal = () => {
    return render(
      <EditNodDateModal
        onCancel={onCancel}
        onSubmit={onSubmit}
        nodDate={defaultNodDate}
      />
    );
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const container = setupEditNodDateModal();

    expect(container).toMatchSnapshot();
  });

  it('should fire cancel event', () => {
    setupEditNodDateModal();
    fireEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  it('should submit event', async() => {
    setupEditNodDateModal();

    fireEvent.click(screen.getByText('Submit'));
    expect(onSubmit).toHaveBeenCalled();
  });
});

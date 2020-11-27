import React from 'react';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';
import { mount } from 'enzyme';

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';
  const defaultNewNodDate = '2020-10-15';

  const setupEditNodDateModal = () => {
    return mount(
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
    const component = setupEditNodDateModal();

    expect(component).toMatchSnapshot();
  });

  it('should fire cancel event', () => {
    const component = setupEditNodDateModal();
    const cancelLink = component.find('button#Edit-NOD-Date-button-id-0');

    cancelLink.simulate('click');
    expect(onCancel).toHaveBeenCalled();
  });

  it('should submit event', async() => {
    const component = setupEditNodDateModal();
    const dateInput = component.find('input[type="date"]');
    const submitButton = component.find('button#Edit-NOD-Date-button-id-1');

    dateInput.simulate('change', { target: { value: defaultNewNodDate } });

    submitButton.simulate('click');

    expect(onSubmit).toHaveBeenCalledWith(defaultNewNodDate);
  });
});

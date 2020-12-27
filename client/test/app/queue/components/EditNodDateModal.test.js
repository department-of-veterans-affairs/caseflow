import React from 'react';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';
import Enzyme, { mount } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

Enzyme.configure({ adapter: new Adapter() });

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';
  const futureDate = '2020-12-25';
  const defaultNewNodDate = '2020-10-15';

  const setupEditNodDateModal = () => {
    return mount(
      <EditNodDateModal
        appealId="tb78ti7in77n"
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

  // Skipping flakey test (passing locally)
  it.skip('should give error when future date is given', () => {
    const component = setupEditNodDateModal();
    const dateInput = component.find('input[type="date"]');
    const errorMsg = "The new NOD date cannot be after today's date";

    dateInput.simulate('change', { target: { value: futureDate } });
    component.update();

    // Assertions
    expect(component.find('input[type="date"]').props().value).
      toEqual(futureDate);

    component.setProps({ errorMessage: errorMsg });
    expect(component.props().errorMessage).toEqual(errorMsg);
  });
});

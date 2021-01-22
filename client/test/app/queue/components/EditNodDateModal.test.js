import React from 'react';
import Enzyme, { mount } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';
import COPY from 'app/../COPY';

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

    dateInput.simulate('change', { target: { value: futureDate } });
    component.update();

    // Assertions
    expect(component.find('input[type="date"]').props().value).
      toEqual(futureDate);

    const errorMessage = component.find('.usa-input-error-message');

    expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE);
  });

  it('should show error when date before 2019-02-19 is given', () => {
    const component = setupEditNodDateModal();
    const dateInput = component.find('input[type="date"]');
    const preAmaDate = '2018-01-01';

    dateInput.simulate('change', { target: { value: preAmaDate } });
    component.update();
    const errorMessage = component.find('.usa-input-error-message');

    expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
  });

  it('should show warning when date is after nodDate', () => {
    const component = setupEditNodDateModal();
    const dateInput = component.find('input[type="date"]');
    const laterThanNodDate = '2021-01-21';

    dateInput.simulate('change', { target: { value: laterThanNodDate } });
    component.update();
    const warningMessage = component.find('.usa-alert-text');

    expect(warningMessage.text()).toEqual(COPY.EDIT_NOD_DATE_WARNING_ALERT_MESSAGE);
  });
});

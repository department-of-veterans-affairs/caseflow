import React from 'react';
import Enzyme, { mount } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';
import COPY from 'app/../COPY';
import SearchableDropdown from 'app/components/SearchableDropdown';

Enzyme.configure({ adapter: new Adapter() });

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';
  const defaultNewNodDate = '2020-10-15';
  const defaultReason = {"label": "New Form/Information Received", "value": "new_info"};

  const setupEditNodDateModal = () => {
    return mount(
      <EditNodDateModal
        appealId="tb78ti7in77n"
        onCancel={onCancel}
        onSubmit={onSubmit}
        nodDate={defaultNodDate}
        reason={defaultReason}
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
    const reasonDropdown = component.find(SearchableDropdown);
    const submitButton = component.find('button#Edit-NOD-Date-button-id-1');

    dateInput.simulate('change', { target: { value: defaultNewNodDate } });
    reasonDropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    reasonDropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });
    
    component.update();
    submitButton.simulate('click');

    expect(onSubmit).toHaveBeenCalledWith(defaultNewNodDate, defaultReason);
  });

  it('should give error when future date is given', () => {
    const component = setupEditNodDateModal();
    const dateInput = component.find('input[type="date"]');
    const newFutureDate = '2021-12-19';
    const submitButton = component.find('button#Edit-NOD-Date-button-id-1');

    dateInput.simulate('change', { target: { value: newFutureDate } });
    component.update();
    const errorMessage = component.find('.usa-input-error-message');

    expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE);
    expect(submitButton.toBeDisabled);
  });

  it('should show error when date before 2019-02-19 is given', () => {
    const component = setupEditNodDateModal();
    const submitButton = component.find('button#Edit-NOD-Date-button-id-1');

    const dateInput = component.find('input[type="date"]');
    const preAmaDate = '2018-01-01';

    dateInput.simulate('change', { target: { value: preAmaDate } });
    component.update();
    const errorMessage = component.find('.usa-input-error-message');

    expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
    expect(submitButton.toBeDisabled);
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
  it('should disable submit button when date is valid and updated and a reason has not been selected', () => {
    const component = setupEditNodDateModal();
    const submitButton = component.find('button#Edit-NOD-Date-button-id-1');
    const dateInput = component.find('input[type="date"]');

    dateInput.simulate('change', { target: { value: defaultNewNodDate } });
    component.update();

    expect(submitButton.toBeDisabled);
  })

  it('should disable submit button if a reason has been selected and date is not valid', () => {
    const component = setupEditNodDateModal();
    const submitButton = component.find('button#Edit-NOD-Date-button-id-1');
    const preAmaDate = '2018-01-01';
    const dateInput = component.find('input[type="date"]');
    const reasonDropdown = component.find(SearchableDropdown);

    dateInput.simulate('change', { target: { value: preAmaDate } });
    reasonDropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    reasonDropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });
    component.update();
    const errorMessage = component.find('.usa-input-error-message');

    expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
    expect(submitButton.toBeDisabled);
  })
});

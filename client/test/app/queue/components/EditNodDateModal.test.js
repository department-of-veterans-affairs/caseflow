import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';
import { DateSelector } from 'app/components/DateSelector';
// import moment from 'moment';
import Enzyme, { mount } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

Enzyme.configure({adapter: new Adapter() });

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';
  const futureDate = true;

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

  it('should give error when future date is given', () => {
    // const enteredDate = moment(futureDate);
    const msg = "The new NOD date cannot be after today's date";
    const modal = mount(
      <EditNodDateModal
        onCancel={onCancel}
        onSubmit={onSubmit}
        nodDate={defaultNodDate}
      />);

    console.log(modal.debug({ verbose: true }));
    // console.log(DateSelector.debug({ verbose: true }));
    // Assertions
    expect(modal.find('#nodDate').prop('errorMessage')).toEqual(msg);

    modal.setProps({ errorMessage: null });
    expect(modal.props().errorMessage).toEqual(null);
    expect(modal).toMatchSnapshot();

    modal.setProps({ errorMessage: msg });
    expect(modal.props().errorMessage).toEqual(msg);
    expect(modal).toMatchSnapshot();

    // modal.setProps({ value: futureDate });
    // // eslint-disable-next-line jest/valid-expect
    // expect(modal.props().errorMessage).toEqual(msg);

    // expect(modal.find({ errorMessage: null })).toEqual(null);
    // modal.setProps({ errorMessage: msg });
    // modal.update();
    // expect(modal.props().errorMessage).toEqual(msg);
  });
});

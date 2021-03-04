import React from 'react';
import ReactDOM from 'react-dom';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { act } from 'react-dom/test-utils';
import Enzyme, { mount } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import { formatDateStr, getDate } from '../../../../app/util/DateUtil';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';
import COPY from 'app/../COPY';
import SearchableDropdown from 'app/components/SearchableDropdown';

Enzyme.configure({ adapter: new Adapter() });

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';
  const appealId = 'tb78ti7in77n';
  const showTimelinessError = false;
  const defaults = {
    appealId,
    onSubmit,
    onCancel,
    nodDate: defaultNodDate,
    showTimelinessError
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { component } = render(<EditNodDateModal {...defaults} />);

    expect(component).toMatchSnapshot();
  });

  it('should fire cancel event', async () => {
    render(<EditNodDateModal {...defaults} />);

    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));

    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation & submission', () => {
    const defaultNewNodDate = '2020-10-15';
    const defaultReason = { label: 'New Form/Information Received', value: 'new_info' };
    const fillForm = async () => {
      //   Set NOD Date
      await fireEvent.change(screen.getByPlaceholderText('mm/dd/yyyy'), { target: { value: defaultNewNodDate } });

      //   Enter Reason
      await fireEvent.change(screen.getByLabelText(/reason for edit/i), { target: { value: defaultReason } });
    };

    it('fires onSubmit with correct values', async () => {

      render(<EditNodDateModal {...defaults} />);

      const submit = screen.getByRole('button', { name: /submit/i });

      await fillForm();

      await userEvent.click(submit);

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith({
          defaultNewNodDate,
          defaultReason,
        });
      });
    });

    it('should give error when future date is given and not submit', async () => {
      render(<EditNodDateModal {...defaults} />);
      // const dateInput = component.find('input[type="date"]');
      const today = new Date();
      const futureDate = getDate(today.setDate(today.getDate() + 2));
      const formattedFutureDate = formatDateStr(futureDate);

      const submit = screen.getByRole('button', { name: /submit/i });

      await fireEvent.change(screen.getByPlaceholderText('mm/dd/yyyy'), { target: { value: formattedFutureDate } });

      await fillForm();

      await userEvent.click(submit);

      await waitFor(() => {
        expect(screen.getByText(COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE)).toBeInTheDocument();
      });
    });
  });

  // it('should show error when date before 2019-02-19 is given', () => {
  //   const component = setupEditNodDateModal();
  //   const submitButton = component.find('button#Edit-NOD-Date-button-id-1');

  //   const dateInput = component.find('input[type="date"]');
  //   const preAmaDate = '2018-01-01';

  //   dateInput.simulate('change', { target: { value: preAmaDate } });
  //   component.update();
  //   const errorMessage = component.find('.usa-input-error-message');

  //   expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
  //   expect(submitButton.getDOMNode()).toHaveProperty('disabled');
  // });

  // it('should show warning when date is after nodDate', () => {
  //   const component = setupEditNodDateModal();
  //   const dateInput = component.find('input[type="date"]');
  //   const laterThanNodDate = '2021-01-21';

  //   dateInput.simulate('change', { target: { value: laterThanNodDate } });
  //   component.update();
  //   const warningMessage = component.find('.usa-alert-text');

  //   expect(warningMessage.text()).toEqual(
  //     COPY.EDIT_NOD_DATE_WARNING_ALERT_MESSAGE
  //   );
  // });
  // it('should disable submit button when date is valid and updated and a reason has not been selected', () => {
  //   const component = setupEditNodDateModal();
  //   const submitButton = component.find('button#Edit-NOD-Date-button-id-1');
  //   const dateInput = component.find('input[type="date"]');

  //   dateInput.simulate('change', { target: { value: defaultNewNodDate } });
  //   component.update();

  //   expect(submitButton.getDOMNode()).toHaveProperty('disabled');
  // });

  // it('should disable submit button if a reason has been selected and date is not valid', () => {
  //   const component = setupEditNodDateModal();
  //   const submitButton = component.find('button#Edit-NOD-Date-button-id-1');
  //   const preAmaDate = '2018-01-01';
  //   const dateInput = component.find('input[type="date"]');
  //   const reasonDropdown = component.find(SearchableDropdown);

  //   dateInput.simulate('change', { target: { value: preAmaDate } });
  //   reasonDropdown.
  //     find('Select').
  //     simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
  //   reasonDropdown.
  //     find('Select').
  //     simulate('keyDown', { key: 'Enter', keyCode: 13 });
  //   component.update();
  //   const errorMessage = component.find('.usa-input-error-message');

  //   expect(errorMessage.text()).toEqual(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
  //   expect(submitButton.getDOMNode()).toHaveProperty('disabled');
  // });
});

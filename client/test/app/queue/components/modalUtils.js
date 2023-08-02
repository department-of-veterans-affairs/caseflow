import userEvent from '@testing-library/user-event';
import { screen, fireEvent } from '@testing-library/react';
import * as uiActions from 'app/queue/uiReducer/uiActions';

/**
 * Creates a reducer for Redux testing in Queue components
 * @param {object} storeValues -- The values to populate the Redux store with
 * @returns {object} -- Returns a "dummy" state update
 */
export const createQueueReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

/**
 * Returns the first appeal ID located within storeValues
 * @param {object} storeValues -- The values that can be used to populate a Redux store with
 * @returns {string} -- Returns the appeal ID of the first appeal parsed from the storeValues
 */
export const getAppealId = (storeValues) => {
  return Object.keys(storeValues.queue.appeals)[0];
};

/**
 * Returns the ID of the first instance of a task type from storeValues
 * @param {object} storeValues -- The values that can be used to populate a Redux store with
 * @returns {string} -- Returns the ID of the first instance of a task type from storeValues
 */
export const getTaskId = (storeValues, taskType) => {
  const tasks = storeValues.queue.amaTasks;

  return Object.keys(tasks).find((key) => (
    tasks[key].type === taskType
  ));
};

/**
 * Finds a textarea in the component and enters the specified text
 * @param {string} instructionsFieldName -- Role name of the textarea field to be populated
 * @param {string} instructions -- The string to enter into the textarea field
 */
export const enterTextFieldOptions = (instructionsFieldName, instructions) => {
  const instructionsField = screen.getByRole('textbox', { name: instructionsFieldName });

  userEvent.type(instructionsField, instructions);
};

/**
 * Finds an input in the component and enters the specified text
 * @param {string} inputLabelName -- Label name of the input field to be populated
 * @param {string} textValue -- The string to enter into the input field
 * Note: The 'inputValue' must use ISO 8601 format when firing a
 * change event on an input of type "date."
 * - valid date inputValue: '2020-05-24'
 * - invalid date inputValue: '24/05/2020'
 */
export const enterInputValue = (inputLabelName, inputValue) => {
  const inputField = screen.getByLabelText(inputLabelName);

  fireEvent.change(inputField, { target: { value: inputValue } });
};

/**
 * Enters the specified number of days into a number field
 * @param {string} customFieldName -- Role name of the field to be populated
 * @param {number} days -- The number of days to enter into the specified field
 */
export const selectCustomDays = (customFieldName, days) => {
  const customField = screen.getByRole('spinbutton', { name: customFieldName });

  userEvent.type(customField, days);
};

/**
 * Finds a radio option with the label passed in and then selects it
 * @param {string} radioSelection -- Label of a radio option to be selected
 */
export const enterModalRadioOptions = (radioSelection) => {
  const radioFieldToSelect = screen.getByLabelText(radioSelection);

  userEvent.click(radioFieldToSelect);
};

/**
 * Finds a dropdown component and then selects the specified option from it
 * @param {string} dropdownName -- Role name of the dropdown component
 * @param {string} dropdownSelection -- The option from the dropdown to be selected
 */
export const selectFromDropdown = async (dropdownName, dropdownSelection) => {
  const dropdown = screen.getByRole('combobox', { name: dropdownName });

  userEvent.click(dropdown);

  userEvent.click(screen.getByRole('option', { name: dropdownSelection }));
};

/**
 * Finds a submission button by its text and then clicks on it
 * @param {string} buttonText -- Text of the button to be clicked
 */
export const clickSubmissionButton = (buttonText) => {
  userEvent.click(screen.getByRole('button', { name: buttonText }));
};


/**
 * Extracts the modal type from a TASK_ACTIONS.json entry
 * @param {string} taskActionValue -- Corresponds to TASK_ACTION.<actionName>.value - Typically "modal/<modalType>"
 * @returns {string} -- Returns the modalType from "modal/<modalType>"
 */
export const trimTaskActionValue = (taskActionValue) => taskActionValue.split('/').pop();

/**
 * Returns a Jest mock for the uiActions.requestPatch method. Can be used to test
 * payload values (like instructions) that are assembled upon modal form submission.
 * @param {object} postData -- Request body data. Used to satisfy reducer actions' params expectations.
 * @returns {object} -- a Jest mock for the uiActions.requestPatch method.
 *  Commonly used to post submission data to backend in modals.
 */
export const createSpyRequestPatch = (postData) => {
  return jest.spyOn(uiActions, 'requestPatch').
    mockImplementation(() => jest.fn(() => Promise.resolve(
      {
        body: {
          ...postData
        }
      }
    )));
};

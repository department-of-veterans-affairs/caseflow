import userEvent from '@testing-library/user-event';
import { screen } from '@testing-library/react';

// Use this to create a basically useless reducer for Redux testing in Queue components
export const createQueueReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

export const getAppealId = (storeValues) => {
  return Object.keys(storeValues.queue.appeals)[0];
};

export const getTaskId = (storeValues, taskType) => {
  const tasks = storeValues.queue.amaTasks;

  return Object.keys(tasks).find((key) => (
    tasks[key].type === taskType
  ));
};

export const enterTextFieldOptions = (instructionsFieldName, instructions) => {
  const instructionsField = screen.getByRole('textbox', { name: instructionsFieldName });

  userEvent.type(instructionsField, instructions);
};

export const enterModalRadioOptions = (radioSelection) => {
  const radioFieldToSelect = screen.getByLabelText(radioSelection);

  userEvent.click(radioFieldToSelect);
};

export const selectFromDropdown = async (dropdownName, dropdownSelection) => {
  const dropdown = screen.getByRole('combobox', { name: dropdownName });

  userEvent.click(dropdown);

  userEvent.click(screen.getByRole('option', { name: dropdownSelection }));
};

export const clickSubmissionButton = (buttonText) => {
  userEvent.click(screen.getByRole('button', { name: buttonText }));
};

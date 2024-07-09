import React from 'react';
import { render, screen, fireEvent} from '@testing-library/react';
import TextareaField from 'app/components/TextareaField';

// Setup the constants
const limit = 10;
const emoji = '😀';
const testValue = 'hello';
const changeSpy = jest.fn();
const name = 'Test Field';
const error = 'Something went wrong';

describe('TextareaField', () => {
  const setup = (props) => {
    return render(
      <TextareaField
      onChange={changeSpy}
      name={name}
      {...props}
      />
    )
  };
  test('Matches snapshot with default props', () => {
    // Run the test
    const {container, asFragment} = setup();

    expect(screen.getByRole('textbox', {name: `${name}` })).toBeInTheDocument();
    expect(container.querySelector('.question-label')).toBeInTheDocument();
    expect(screen.getByText(name)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Can accept input', () => {
    // Setup the test
    const { asFragment} = setup();

    // Run the test
    const textField = screen.getByRole('textbox', {name: `${name}` });
    fireEvent.change(textField, { target: { value: testValue } });

    // Assertions
    expect(changeSpy).toHaveBeenCalledWith(testValue);
    expect(textField.value).toEqual(testValue);
    expect(asFragment()).toMatchSnapshot();
  });

  test('Respects disabled prop on the textarea field', () => {
    // Setup the test
    const { asFragment} = setup({
      disabled: true
    });

    const textField = screen.getByRole('textbox', {name: `${name}` });

    // Assertions
    expect(textField).toBeDisabled();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Respects optional prop on the textarea field', () => {
    // Setup the test
    const {container, asFragment} = setup({
      optional: true
    });

    // Assertions
    expect(screen.getByRole('textbox', {name: `${name} Optional` })).toBeInTheDocument();
    expect(screen.getByText('Optional')).toBeInTheDocument();
    expect(container.querySelector('.cf-optional')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Respects required prop on the textarea field', () => {
    // Setup the test
    const {container, asFragment} = setup({
      required: true
    });

    // Assertions
    expect(screen.getByRole('textbox', {name: `${name} Required` })).toBeInTheDocument();
    expect(screen.getByText('Required')).toBeInTheDocument();
    expect(container.querySelector('.cf-required')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays screen-reader only label when hideLabel prop is true', () => {
    // Setup the test
    const {container, asFragment} = setup({
      hideLabel: true
    });

    // Assertions
    expect(container.querySelector('.sr-only')).toBeInTheDocument();
    expect(container.querySelector('.question-label')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays a bold label when strongLabel prop is true', () => {
    // Setup the test
    const {container, asFragment} = setup({
      strongLabel: true
    });

    // Assertions
    const strongElement = container.querySelector('strong');
    expect(strongElement).toHaveTextContent(name);
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays error message when present', () => {
    // Setup the test
    const {container, asFragment} = setup({
      errorMessage: error
    });

    // Assertions
    expect(screen.getByText(error)).toBeInTheDocument();
    expect(container.querySelector('.usa-input-error')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays character count when maxlength and value are present', () => {
    // Setup the test
    const { asFragment} = setup({
      maxlength: limit,
      value: testValue
    });

    // Assertions
    expect(screen.getByText(`${limit - testValue.length} characters left`)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Emojis consume 2 characters', () => {
    // Setup the test
    const { asFragment} = setup({
      maxlength: 2,
      value: emoji
    });

    // Assertions
    expect(screen.getByText('0 characters left')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not display character count when maxlength is present, but value is not present', () => {
    // Setup the test
    const {container, asFragment} = setup({
      maxlength: limit
    });

    // Assertions
    const iElements = container.querySelectorAll('i');
    expect(iElements).toHaveLength(0);
    expect(asFragment()).toMatchSnapshot();
  });

  test('Respects characterLimitTopRight prop on the textarea field', () => {
    // Setup the test
    const {container, asFragment} = setup({
      maxlength: limit,
      characterLimitTopRight: true,
      value: 'Notes'
    });

    const iElements = container.querySelectorAll('i');
    expect(iElements).toHaveLength(1);
    const pElement = container.querySelector('p[style="float: right; margin-bottom: 0px; line-height: inherit;"]');
    expect(pElement).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  })
});

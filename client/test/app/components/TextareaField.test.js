import React from 'react';
import { mount } from 'enzyme';
import TextareaField from 'app/components/TextareaField';
import { FormLabel } from 'app/components/FormLabel';

// Setup the constants
const limit = 10;
const emoji = '😀';
const testValue = 'hello';
const changeSpy = jest.fn();
const name = 'Test Field';
const error = 'Something went wrong';

describe('TextareaField', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const textField = mount(<TextareaField onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('textarea')).toHaveLength(1);
    expect(textField.find('label').prop('className')).toEqual('question-label');
    expect(textField.find(FormLabel).prop('name')).toEqual(name);
    expect(textField.prop('disabled')).toEqual(false);
    expect(textField.prop('optional')).toEqual(false);
    expect(textField.prop('required')).toEqual(false);
    expect(textField).toMatchSnapshot();
  });

  test('Can accept input', () => {
    // Setup the test
    const textField = mount(<TextareaField onChange={changeSpy} name={name} />);

    // Run the test
    textField.find('textarea').simulate('change', { target: { value: testValue } });

    // Assertions
    expect(changeSpy).toHaveBeenCalledWith(testValue);
    expect(textField).toMatchSnapshot();
  });

  test('Respects disabled prop on the textarea field', () => {
    // Setup the test
    const textField = mount(<TextareaField disabled onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('textarea').prop('disabled')).toEqual(true);
    expect(textField).toMatchSnapshot();
  });

  test('Respects optional prop on the textarea field', () => {
    // Setup the test
    const textField = mount(<TextareaField optional onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find(FormLabel).prop('optional')).toEqual(true);
    expect(textField.find('.cf-optional').text()).toEqual('Optional');
    expect(textField).toMatchSnapshot();
  });

  test('Respects required prop on the textarea field', () => {
    // Setup the test
    const textField = mount(<TextareaField required onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find(FormLabel).prop('required')).toEqual(true);
    expect(textField.find('.cf-required').text()).toEqual('Required');
    expect(textField).toMatchSnapshot();
  });

  test('Displays screen-reader only label when hideLabel prop is true', () => {
    // Setup the test
    const textField = mount(<TextareaField hideLabel onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('label').prop('className')).toEqual('sr-only question-label');
    expect(textField).toMatchSnapshot();
  });

  test('Displays a bold label when strongLabel prop is true', () => {
    // Setup the test
    const textField = mount(<TextareaField strongLabel onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('strong').text()).toEqual(name);
    expect(textField).toMatchSnapshot();
  });

  test('Displays error message when present', () => {
    // Setup the test
    const textField = mount(<TextareaField errorMessage={error} onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('.usa-input-error-message').text()).toEqual(error);
    expect(textField).toMatchSnapshot();
  });

  test('Displays character count when maxlength and value are present', () => {
    // Setup the test
    const textField = mount(<TextareaField maxlength={limit} value={testValue} onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('i').text()).toEqual(`${limit - testValue.length} characters left`);
    expect(textField).toMatchSnapshot();
  });

  test('Emojis consume 2 characters', () => {
    // Setup the test
    const textField = mount(<TextareaField maxlength={2} value={emoji} onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('i').text()).toEqual('0 characters left');
    expect(textField).toMatchSnapshot();

  });

  test('Does not display character count when maxlength is present, but value is not present', () => {
    // Setup the test
    const textField = mount(<TextareaField maxlength={limit} onChange={changeSpy} name={name} />);

    // Assertions
    expect(textField.find('i')).toHaveLength(0);
    expect(textField).toMatchSnapshot();
  });

  test('Respects characterLimitTopRight prop on the textarea field', () => {
    // Setup the test
    const textField = mount(
      <TextareaField
        maxlength={limit}
        onChange={changeSpy}
        name={name}
        characterLimitTopRight={true}
        value={'Notes'}
      />
    );
    expect(textField.find('i')).toHaveLength(1);
    expect(textField.find('p').first().props().style).toEqual(
      { float: 'right', marginBottom: 0, lineHeight: 'inherit' }
    );
    expect(textField).toMatchSnapshot();
  })
});

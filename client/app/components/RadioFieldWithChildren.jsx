import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import RequiredIndicator from './RequiredIndicator';
import StringUtil from '../util/StringUtil';
import MaybeAddTooltip from './TooltipHelper';

import RadioInput from './RadioInput';
import { extractFieldProps } from './fieldUtils';

import { helpText } from './RadioField.module.scss';
const RadioFieldHelpText = ({ help, className }) => {
  const helpClasses = classNames('cf-form-radio-help', helpText, className);

  return <div className={helpClasses}>{help}</div>;
};

RadioFieldHelpText.propTypes = {
  help: PropTypes.string.isRequired,
  className: PropTypes.string,
};

/**
 * Clone of RadioField button component that allows children objects .
 * See StyleGuideRadioField.jsx for usage examples.
 */

// Correspondence: Refactor Candidate
// CodeClimate: Identical blocks of code with RadioField
/* eslint-disable */

export const RadioFieldWithChildren = (props) => {

  const { id, className, label, inputRef } = extractFieldProps(props);

  const {
    inputProps,
    name,
    options,
    value,
    onChange,
    required,
    errorMessage,
    strongLabel,
    hideLabel,
    styling,
    vertical,
    optionsStyling
  } = props;

  const isVertical = useMemo(() => props.vertical || props.options.length > 2, [
    vertical,
    options,
  ]);

  const radioClass = className.
    concat(isVertical ? 'cf-form-radio' : 'cf-form-radio-inline').
    concat(errorMessage ? 'usa-input-error' : '');

  const labelClass = hideLabel ? 'usa-sr-only' : '';

  // Since HTML5 IDs should not contain spaces...
  const idPart = StringUtil.html5CompliantId(id || name);

  const labelContents = (
    <span>
      {label || name} {required && <RequiredIndicator />}
    </span>
  );

  const isDisabled = (option) => Boolean(option.disabled);

  const handleChange = (event) => onChange?.(event.target.value);
  const controlled = useMemo(() => typeof value !== 'undefined', [value]);

  return (
    <fieldset className={radioClass.join(' ')} {...styling}>
      <legend className={labelClass}>
        {strongLabel ? <strong>{labelContents}</strong> : labelContents}
      </legend>

      {errorMessage && (
        <span className="usa-input-error-message" tabIndex={0}>{errorMessage}</span>
      )}

      <div className="cf-form-radio-options" style={optionsStyling}>
        {options.map((option, i) => {
          const optionDisabled = isDisabled(option);
          const radioField = (<div
            className="cf-form-radio-option"
            key={`${idPart}-${option.value}-${i}`}
          >
            <RadioInput
              handleChange={handleChange}
              name={name}
              idPart={idPart}
              option={option}
              controlled={controlled}
              value={value}
              inputRef={inputRef}
              inputProps={inputProps}
            />
            <label
              className={optionDisabled ? 'disabled' : ''}
              htmlFor={`${idPart}_${option.value}`}
            >
              {option.displayText || option.displayElem}
            </label>
            {option.displayElement && option.element}
            {option.help && <RadioFieldHelpText help={option.help} />}
          </div>
          );

          return (
            <MaybeAddTooltip key={option.value} option={option}>
              {radioField}
            </MaybeAddTooltip>
          );
        })}
      </div>
    </fieldset>
  );
};

RadioFieldWithChildren.defaultProps = {
  required: false,
  displayElement: false,
  className: ['usa-fieldset-inputs'],
};

RadioFieldWithChildren.propTypes = {
  id: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  required: PropTypes.bool,
  // Pass a ref to the `input` element
  inputRef: PropTypes.oneOfType([
    // Either a function
    PropTypes.func,
    // Or the instance of a DOM native element (see the note about SSR)
    PropTypes.shape({ current: PropTypes.instanceOf(Element) }),
  ]),
  // Props to be applied to the `input` element
  inputProps: PropTypes.object,
  // Text to display in a `legend` element for the radio group fieldset
  label: PropTypes.node,
  // String to be applied to the `name` attribute of all the `input` elements
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when value is changed
   * @param {string} value The current value of the component
   */
  onChange: PropTypes.func,
  // an array of options used to define individual radio inputs
  options: PropTypes.arrayOf(
    PropTypes.shape({
    // Text to be used as label for individual radio input
      displayText: PropTypes.node,
      // The `value` attribute for the radio input
      value: PropTypes.string,
      // Help text to be displayed below the label
      help: PropTypes.string,
      // The child element to display under the radiofield option
      element: PropTypes.element,
      // Used to control visibility of child element
      displayElement: PropTypes.bool
    })
  ),
  // The value of the named `input` element(s); required for a controlled component
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),
  // Stack `input` elements vertically (automatic for more than two options)
  vertical: PropTypes.bool,
  errorMessage: PropTypes.string,
  strongLabel: PropTypes.bool,
  hideLabel: PropTypes.bool,
  styling: PropTypes.object,
  optionsStyling: PropTypes.object
};

export default RadioFieldWithChildren;

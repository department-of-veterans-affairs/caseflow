import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import RequiredIndicator from './RequiredIndicator';
import StringUtil from '../util/StringUtil';
import Tooltip from './Tooltip';

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
 * Radio button component.
 *
 * See StyleGuideRadioField.jsx for usage examples.
 *
 */

export const RadioField = (props) => {
  const {
    id,
    className,
    label,
    inputRef,
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
    vertical
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

  const maybeAddTooltip = (option, radioField) => {
    if (option.tooltipText) {
      const idKey = `tooltip-${option.value}`;

      return <Tooltip
        key={idKey}
        id={idKey}
        text={option.tooltipText}
        position="right"
        className="cf-radio-option-tooltip"
        offset={{ right: 15 }}
      >
        {radioField}
      </Tooltip>;
    }

    return radioField;
  };

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

      <div className="cf-form-radio-options">
        {options.map((option, i) => {
          const optionDisabled = isDisabled(option);

          const radioField = (<div
            className="cf-form-radio-option"
            key={`${idPart}-${option.value}-${i}`}
          >
            <input
              name={name}
              onChange={handleChange}
              type="radio"
              id={`${idPart}_${option.value}`}
              value={option.value}
              // eslint-disable-next-line no-undefined
              checked={controlled ? value === option.value : undefined}
              disabled={optionDisabled}
              ref={inputRef}
              {...inputProps}
            />
            <label
              className={optionDisabled ? 'disabled' : ''}
              htmlFor={`${idPart}_${option.value}`}
            >
              {option.displayText || option.displayElem}
            </label>
            {option.help && <RadioFieldHelpText help={option.help} />}
          </div>
          );

          return maybeAddTooltip(option, radioField);
        })}
      </div>
    </fieldset>
  );
};

RadioField.defaultProps = {
  required: false,
  className: ['usa-fieldset-inputs'],
};

RadioField.propTypes = {
  id: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  required: PropTypes.bool,

  /**
   * Pass a ref to the `input` element
   */
  inputRef: PropTypes.oneOfType([
    // Either a function
    PropTypes.func,
    // Or the instance of a DOM native element (see the note about SSR)
    PropTypes.shape({ current: PropTypes.instanceOf(Element) }),
  ]),

  /**
   * Props to be applied to the `input` element
   */
  inputProps: PropTypes.object,

  /**
   * Text to display in a `legend` element for the radio group fieldset
   */
  label: PropTypes.node,

  /**
   * String to be applied to the `name` attribute of all the `input` elements
   */
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when value is changed
   *
   * @param {string} value The current value of the component
   */
  onChange: PropTypes.func,

  /**
   * An array of options used to define individual radio inputs
   */
  options: PropTypes.arrayOf(
    PropTypes.shape({

      /**
       * Text to be used as label for individual radio input
       */
      displayText: PropTypes.node,

      /**
       * The `value` attribute for the radio input
       */
      value: PropTypes.string,

      /**
       * Help text to be displayed below the label
       */
      help: PropTypes.string,
    })
  ),

  /**
   * The value of the named `input` element(s); required for a controlled component
   */
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),

  /**
   * Stack `input` elements vertically (automatic for more than two options)
   */
  vertical: PropTypes.bool,
  errorMessage: PropTypes.string,
  strongLabel: PropTypes.bool,
  hideLabel: PropTypes.bool,
  styling: PropTypes.object
};

export default RadioField;

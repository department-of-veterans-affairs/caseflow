import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import RequiredIndicator from './RequiredIndicator';
import StringUtil from '../util/StringUtil';
import Tooltip from './Tooltip';

import { helpText } from './RadioField.module.scss';
import Checkbox from './Checkbox';

import connect from 'react-redux/lib/connect/connect';
import { useDispatch } from 'react-redux';

import { bindActionCreators } from 'redux';

import {setMSTCheckbox} from "../intake/actions/intake"
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
<<<<<<< Updated upstream
    vertical
=======
    vertical,
    defaultMst,
    setMst,
    getMst
>>>>>>> Stashed changes
  } = props;
  {/* 
dioField.jsx:59 Uncaught TypeError: Cannot read properties of undefined (reading 'props')
    at onClickMSTCheckbox (RadioField.jsx:59:10)
    at eval (RadioField.jsx:132:48)
    at Array.map (<anonymous>)
    at RadioField (RadioField.jsx:108:18)
    at renderWithHooks (react-dom.development.js:14803:1)
    at updateFunctionComponent (react-dom.development.js:17034:1)
    at beginWork (react-dom.development.js:18610:1)
    at HTMLUnknownElement.callCallback (react-dom.development.js:188:1)
    at Object.invokeGuardedCallbackDev (react-dom.development.js:237:1)
    at invokeGuardedCallback (react-dom.development.js:292:1)
*/}

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

<<<<<<< Updated upstream
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

=======
  
>>>>>>> Stashed changes
  const handleChange = (event) => onChange?.(event.target.value);

  const controlled = useMemo(() => typeof value !== 'undefined', [value]);

  //pass value from props 
  const displayMSTorPactInfo = (issueId, indexId) => {
    if(issueId === indexId && props.renderCheckboxes)
      return true;

    return false;
  }

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
              {props.onChange}
              {displayMSTorPactInfo(option.value, props.value) && <Checkbox label="Issue is related to Military Sexual Trauma (MST)" id={option.value}  
              value={defaultMst} onClick={setMst()}/>}
             {displayMSTorPactInfo(option.value, props.value) && <Checkbox label="Issue is related to PACT Act" onClick={console.log("clicked")}/>}
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
  value: PropTypes.string,

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

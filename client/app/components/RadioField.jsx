import React from 'react';
import PropTypes from 'prop-types';

import classNames from 'classnames';

import RequiredIndicator from './RequiredIndicator';
import StringUtil from '../util/StringUtil';

import { helpText } from './RadioField.module.scss';

const RadioFieldHelpText = ({ help, className }) => {
  const helpClasses = classNames('cf-form-radio-help', helpText, className);

  return <div className={helpClasses}>{help}</div>;
};

RadioFieldHelpText.propTypes = {
  help: PropTypes.string.isRequired,
  className: PropTypes.string
};

/**
 * Radio button component.
 *
 * See StyleGuideRadioField.jsx for usage examples.
 *
 */

export default class RadioField extends React.Component {
  isVertical() {
    return this.props.vertical || this.props.options.length > 2;
  }

  render() {
    const {
      id,
      className,
      label,
      name,
      options,
      value,
      onChange,
      required,
      errorMessage,
      strongLabel,
      hideLabel,
      styling
    } = this.props;

    const radioClass = className.
      concat(this.isVertical() ? 'cf-form-radio' : 'cf-form-radio-inline').
      concat(errorMessage ? 'usa-input-error' : '');

    const labelClass = hideLabel ? 'usa-sr-only' : '';

    // Since HTML5 IDs should not contain spaces...
    const idPart = StringUtil.html5CompliantId(id || name);

    const labelContents = (
      <span>
        {label || name} {required && <RequiredIndicator />}
      </span>
    );

    return (
      <fieldset className={radioClass.join(' ')} {...styling}>
        <legend className={labelClass}>{strongLabel ? <strong>{labelContents}</strong> : labelContents}</legend>

        {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}

        <div className="cf-form-radio-options">
          {options.map((option, i) => (
            <div className="cf-form-radio-option" key={`${idPart}-${option.value}-${i}`}>
              <input
                name={name}
                onChange={(event) => {
                  onChange(event.target.value);
                }}
                type="radio"
                id={`${idPart}_${option.value}`}
                value={option.value}
                checked={value === option.value}
                disabled={Boolean(option.disabled)}
              />
              <label className={option.disabled ? 'disabled' : ''} htmlFor={`${idPart}_${option.value}`}>
                {option.displayText || option.displayElem}
              </label>
              {option.help && <RadioFieldHelpText help={option.help} />}
            </div>
          ))}
        </div>
      </fieldset>
    );
  }
}

RadioField.defaultProps = {
  required: false,
  className: ['usa-fieldset-inputs']
};

RadioField.propTypes = {
  id: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  required: PropTypes.bool,
  label: PropTypes.node,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      displayText: PropTypes.node,
      value: PropTypes.string,
      help: PropTypes.string
    })
  ),
  value: PropTypes.string,
  vertical: PropTypes.bool,
  errorMessage: PropTypes.string,
  strongLabel: PropTypes.bool,
  hideLabel: PropTypes.bool,
  styling: PropTypes.object
};

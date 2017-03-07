import React, { PropTypes } from 'react';

export default class Checkbox extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.checked);
  }

  render() {
    let {
      label,
      name,
      required,
      value
    } = this.props;

    let className = `question-label `
    return <div className={`cf-form-checkboxes checkbox-wrapper-${name}`}>
      <div className="cf-form-checkbox">

      <input
        name={name}
        onChange={this.onChange}
        type="checkbox"
        id={name}
        checked={value}
      />
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      </div>
    </div>;
  }
}
Checkbox.defaultProps = {
  required: false,
  fullWidth: false
};

Checkbox.propTypes = {
  label: PropTypes.node,
  fullWidth: PropTypes.bool.isRequired,
  name: PropTypes.string.isRequired,
  required: PropTypes.bool.isRequired,
  onChange: PropTypes.func,
  value: PropTypes.bool
};

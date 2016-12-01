import React, { PropTypes } from 'react';
export default class Checkbox extends React.Component {
  onChange = (event) => {
    this.props.onChange(this.props.name, event.target.checked);
  }

  render() {
    let {
      value,
      label,
      name
    } = this.props;

    return <div className="cf-form-checkboxes">
      <div className="cf-form-checkbox">

      <input
        name={name}
        onChange={this.onChange}
        type="checkbox"
        id={name}
        checked={value}
      />
      <label className="question-label" htmlFor={name}>{label || name}</label>
      </div>
    </div>;
  }
}

Checkbox.propTypes = {
  value: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func
};

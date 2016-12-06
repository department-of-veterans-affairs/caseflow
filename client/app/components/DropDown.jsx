import React, { PropTypes } from 'react';
export default class DropDown extends React.Component {
  onChange = (event) => {
    this.props.onChange(this.props.name, event.target.value);
  }

  render() {
    let {
      label,
      name,
      options,
      value,
      readOnly
    } = this.props;

    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>{label || name}</label>
      <select value={value} onChange={this.onChange} id={name} readOnly={readOnly}>
        {options.map((option, index) =>
          <option
            value={option}
            id={`${name}_${option}`}
            key={index}>{option}
          </option>
        )}
      </select>
    </div>;
  }
}

DropDown.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  readOnly: PropTypes.bool,
  value: PropTypes.string
};

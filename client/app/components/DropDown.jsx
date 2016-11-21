import React, { PropTypes } from 'react';
export default class DropDown extends React.Component {
  render() {
    let {
      label,
      name,
      onChange,
      options,
      selected,
      readOnly
    } = this.props;

    return (<div className="cf-form-dropdown">
      <label className="question-label">{label || name}</label>
      <select value={selected} onChange={onChange} readOnly={readOnly}>
        {options.map((option, index) => (
          <option value={option} key={index}>{option}</option>
        ))}
      </select>
    </div>);
  }
}

DropDown.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  options: PropTypes.array,
  onChange: PropTypes.func,
  selected: PropTypes.string,
  readOnly: PropTypes.bool
};

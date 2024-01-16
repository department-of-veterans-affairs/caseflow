import React from 'react';
import PropTypes from 'prop-types';
import cx from 'classnames';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const StaticLever = ({ lever }) => {
  const renderValue = () => {
    switch (lever.data_type) {
    case ACD_LEVERS.data_types.boolean:
      return lever.value.toString();
    case ACD_LEVERS.data_types.number:
      return `${lever.value} ${lever.unit}`;
    case ACD_LEVERS.data_types.radio:
      return lever.options.find((option) => option.value === lever.value)?.text;
    case ACD_LEVERS.data_types.combination:
      return `${lever.value} ${lever.unit}`;
    default:
      return null;
    }
  };

  const valueWithUnit = renderValue();
  const valueArray = valueWithUnit.split(' ');
  const value = valueArray[0];
  const unit = valueArray[1];

  return (
    <tbody>
      <tr>
        <td className="title-styling">{lever.title}</td>
      </tr>
      <tr>
        <td className={cx('cf-lead-paragraph', 'description-styling')}>{lever.description}</td>
        <td className={cx('cf-lead-paragraph', 'value-styling')}>
          <span className="value-right-styling">{value} </span>
          <span>{unit}</span>
        </td>
      </tr>
    </tbody>
  );
};

StaticLever.propTypes = {
  lever: PropTypes.shape({
    title: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    data_type: PropTypes.string.isRequired,
    value: PropTypes.oneOfType([PropTypes.bool, PropTypes.number, PropTypes.string]).isRequired,
    unit: PropTypes.string.isRequired,
    is_toggle_active: PropTypes.bool,
    is_disabled_in_ui: PropTypes.bool,
    options: PropTypes.arrayOf(
      PropTypes.shape({
        item: PropTypes.string.isRequired,
        data_type: PropTypes.string.isRequired,
        value: PropTypes.oneOfType([PropTypes.bool, PropTypes.number, PropTypes.string]).isRequired,
        text: PropTypes.string,
        unit: PropTypes.string,
      })
    ),
  }).isRequired,
};
export default StaticLever;

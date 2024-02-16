import React from 'react';
import PropTypes from 'prop-types';
import cx from 'classnames';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const StaticLever = ({ lever }) => {
  // Requires space between value and unit, false for percentage values
  let requiredSeparator = true;

  const renderValue = () => {
    let leverValueString = '';

    switch (lever.data_type) {
    case ACD_LEVERS.data_types.boolean:
      leverValueString = lever.value.toString();

      return leverValueString.charAt(0).toUpperCase() + leverValueString.slice(1);
    case ACD_LEVERS.data_types.number:
      requiredSeparator = false;

      return `${(lever.value * 100).toFixed(0)}`;
    case ACD_LEVERS.data_types.radio:
      return lever.options.find((option) => option.value === lever.value)?.text;
    case ACD_LEVERS.data_types.combination:
      return `${lever.value}`;
    default:
      return null;
    }
  };

  const formattedValue = renderValue();

  return (
    <tbody>
      <tr>
        <td className="title-styling">{lever.title}</td>
      </tr>
      <tr>
        <td className={cx('cf-lead-paragraph', 'description-styling')} id={`${lever.item}-description`}>
          {lever.description}
        </td>
        <td className={cx('cf-lead-paragraph', 'value-styling')} id={`${lever.item}-product`}>
          <span className="value-right-styling" id={`${lever.item}-value`}>{formattedValue}
            <span className={requiredSeparator ? 'unit-with-separator' : null} id={cx(`${lever.item}-unit`)}>
              {lever.unit}
            </span>
          </span>
        </td>
      </tr>
    </tbody>
  );
};

StaticLever.propTypes = {
  lever: PropTypes.shape({
    item: PropTypes.string.isRequired,
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

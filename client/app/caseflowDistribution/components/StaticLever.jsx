import React from 'react';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/StaticLevers.module.scss';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const StaticLever = ({ lever }) => {
  const renderValue = () => {
    switch (lever.data_type) {
    case ACD_LEVERS.boolean:
      return lever.value.toString();
    case ACD_LEVERS.number:
      return `${lever.value} ${lever.unit}`;
    case ACD_LEVERS.radio:
      return lever.options.find((option) => option.value === lever.value)?.text;
    case ACD_LEVERS.combination:
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
        <td className={styles.titleStyling}>{lever.title}</td>
      </tr>
      <tr>
        <td className={`cf-lead-paragraph ${styles.descriptionStyling}`}>{lever.description}</td>
        <td className={`cf-lead-paragraph ${styles.valueStyling}`}>
          <span className={styles.valueRightStyling}>{value} </span>
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
    is_active: PropTypes.bool.isRequired,
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

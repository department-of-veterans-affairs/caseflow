import React from 'react';
import PropTypes from 'prop-types';

const StaticLever = ({ lever }) => {
  const renderValue = () => {
    switch (lever.data_type) {
    case 'boolean':
      return lever.value.toString();
    case 'number':
      return `${lever.value} ${lever.unit}`;
    case 'radio':
      return lever.options.find((option) => option.value === lever.value)?.text;
    case 'combination':
      return `${lever.value} ${lever.unit}`;
    default:
      return null;
    }
  };
  const titleStyling = {
    border: 'none',
    paddingTop: '0',
    marginTop: '0',
    paddingBottom: '0',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: 'bold',
    fontSize: '19px',
    lineHeight: '1.5em/25px',
    columnSpan: 'all',
  };
  const descriptionStyling = {
    width: '70%',
    border: 'none',
    paddingTop: '0',
    marginTop: '0',
    paddingRight: '20px',
    paddingBottom: '20px',
    verticalAlign: 'text-top',
    borderBottom: '1px solid #ccc',
  };
  const valueStyling = {
    width: '30%',
    border: 'none',
    paddingTop: '0',
    marginTop: '0',
    whiteSpace: 'noWrap',
    paddingBottom: '20px',
    paddingRight: '20px',
    verticalAlign: 'text-top',
    borderBottom: '1px solid #ccc',
  };
  const tableStyling = {
    borderCollapse: 'collapse',
    width: '100%',
  };
  const valueWithUnit = renderValue();
  const valueArray = valueWithUnit.split(' ');
  const value = valueArray[0];
  const unit = valueArray[1];

  return (
    <table style={tableStyling}>
      <tbody>
        <tr>
          <td style={titleStyling}>{lever.title}</td>
        </tr>
        <tr>
          <td className="cf-lead-paragraph" style={descriptionStyling}>{lever.description}</td>
          <td className="cf-lead-paragraph" style={valueStyling}>
            <span style={{ marginRight: '5px' }}>{value} </span>
            <span>{unit}</span>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

StaticLever.propTypes = {
  lever: PropTypes.shape({
    title: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    data_type: PropTypes.string.isRequired,
    value: PropTypes.oneOfType([PropTypes.bool, PropTypes.number]).isRequired,
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

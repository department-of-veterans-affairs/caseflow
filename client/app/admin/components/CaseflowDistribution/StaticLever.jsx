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
    paddingTop: '20px',
    marginTop: '0',
    paddingBottom: '0',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: 'bold',
    fontSize: '17px',
    lineHeight: '1.5em/33px',
    columnSpan: 'all',
  };
  const descriptionStyling = {
    border: 'none',
    paddingTop: '0',
    marginTop: '0',
    maxWidth: '750px',
    paddingRight: '20px',
    paddingBottom: '20px',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: '400',
    fontSize: '15px',
    lineHeight: '1.5em/33px',
    borderBottom: '1px solid #ccc',
  };
  const valueStyling = {
    border: 'none',
    paddingTop: '0',
    marginTop: '0',
    whiteSpace: 'noWrap',
    paddingBottom: '20px',
    paddingRight: '20px',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: '400',
    fontSize: '15px',
    lineHeight: '1.5em/33px',
    textAlign: 'right',
    borderBottom: '1px solid #ccc',
  };
  const tableStyling = {
    borderCollapse: 'collapse',
  };
  const valueWithUnit = renderValue();
  const valueArray = valueWithUnit.split(' ');
  const value = valueArray[0];
  const unit = valueArray[1];

  return (
    <div>
      <table style={tableStyling}>
        <tbody>
          <tr>
            <td style={titleStyling}>{lever.title}</td>
          </tr>
          <tr>
            <td style={descriptionStyling}>{lever.description}</td>
            <td style={valueStyling}>
              <span style={{ marginRight: '5px' }}>{value} </span>
              <span>{unit}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
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

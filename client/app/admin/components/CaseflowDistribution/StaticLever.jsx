import React from 'react';
import PropTypes from 'prop-types';
import Table from '../../../components/Table';

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

  const columns = [
    {
      header: '',
      valueName: 'title',
      align: 'left',
      rowSpan: 2,
    },
    {
      header: 'Data Elements',
      valueName: 'description',
      align: 'left',
    },
    {
      header: 'Value',
      valueFunction: renderValue,
      align: 'center',
    },
  ];

  const rowObjects = [
    {
      title: lever.title,
      description: lever.description,
      value: renderValue(),
    },
  ];

  return (
    <Table columns={columns} rowObjects={rowObjects} />
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

import React from 'react';
import PropTypes from 'prop-types';

const NotificationResponseDetails = ({ response, date, time }) => {
  const tableCols = ['Appellant Acknowledgement', 'Response Date', 'Response Time', '', '', ''];
  const tableData = [response, date, time, '', '', ''];

  // Renders the columns titles
  // cols - The columns titles
  // Return the columns
  const renderCol = (cols) => {
    return cols.map((col) => <td><strong>{col}</strong></td>);
  };

  // Renders the data for each column
  // data - The values
  // Return the data
  const renderData = (data) => {
    return data.map((value) => <td>{value}</td>);
  };

  return (
    <>
      <tr style={{ borderBottom: 'hidden' }}>
        {renderCol(tableCols)}
      </tr>
      <tr>
        {renderData(tableData)}
      </tr>
    </>
  );
};

NotificationResponseDetails.propTypes = {
  response: PropTypes.string,
  date: PropTypes.string,
  time: PropTypes.string
};

export default NotificationResponseDetails;

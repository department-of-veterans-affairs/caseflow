import React, { useState } from 'react';

const NotificationResponseDetails = () => {
  const [response, setResponse] = useState('-');
  const [date, setDate] = useState('-');
  const [time, setTime] = useState('-');

  const tableCols = ['Appellant Acknowledgement', 'Response Date', 'Response Time', '', '', ''];

  const renderTable = (cols) => {
    return cols.map((col) => <td><strong>{col}</strong></td>);
  };

  return (
    <tr >
      {renderTable(tableCols)}
    </tr>
  );
};

export default NotificationResponseDetails;

import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

const CollapsibleTable = (props) => {
  const { returnedAppealJobs } = props;
  const [expandedRows, setExpandedRows] = useState([]);
  const [allExpanded, setAllExpanded] = useState(true);

  useEffect(() => {
    const allRowIds = returnedAppealJobs.map((row) => row.id);

    setExpandedRows(allRowIds);
  }, [returnedAppealJobs]);

  const toggleAllRows = () => {

    if (allExpanded) {
      // Collapse all rows
      setExpandedRows([]);
    } else {
      // Expand all rows
      const allRowIds = returnedAppealJobs.map((row) => row.id);

      setExpandedRows(allRowIds);
    }
    setAllExpanded(!allExpanded);
  };

  const renderRowDetails = (row) => {
    return (
      <tr key={`row-expanded-${row.id}`}>
        <td>{row.created_at}</td>
        <td>{row.returned_appeals.join(', ')}</td>
        <td>{JSON.parse(row.stats).message}</td>
      </tr>
    );
  };

  return (
    <div>
      <button onClick={toggleAllRows}>
        {allExpanded ? 'Collapse All' : 'Expand All'}
      </button>
      <table border="1" width="100%" style={{ marginTop: '10px' }}>
        <thead>
          <tr>
            <th>Created At</th>
            <th>Returned Appeals</th>
            <th>Stats</th>
          </tr>
        </thead>
        <tbody>
          {returnedAppealJobs.map((row) => (
            <React.Fragment key={row.id}>
              {expandedRows.includes(row.id) && renderRowDetails(row)}
            </React.Fragment>
          ))}
        </tbody>
      </table>
    </div>
  );
};

CollapsibleTable.propTypes = {
  returnedAppealJobs: PropTypes.array,
};

export default CollapsibleTable;

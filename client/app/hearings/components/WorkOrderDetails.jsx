import React, { useEffect, useState } from 'react';
import ApiUtil from '../../util/ApiUtil';
import QueueTable from '../../queue/QueueTable';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const columns = [
  { name: 'docket_number', header: 'Docket Number', valueFunction: (row) => row.docket_number },
  { name: 'first_name', header: 'First Name', valueFunction: (row) => row.first_name },
  { name: 'last_name', header: 'Last Name', valueFunction: (row) => row.last_name },
  { name: 'types', header: 'Types', valueFunction: (row) => row.types },
  { name: 'hearing_date', header: 'Hearing Date', valueFunction: (row) => row.hearing_date },
  { name: 'regional_office', header: 'RO', valueFunction: (row) => row.regional_office },
  { name: 'judge_name', header: 'VLJ', valueFunction: (row) => row.judge_name },
  { name: 'case_type', header: 'Appeal Type', valueFunction: (row) => row.case_type }
];

// CSS styles
const styles = css({
  '& div *': {
    outline: 'none',
  },
  '& table': {
    marginTop: 0,
    position: 'relative',
  },
  '& td': {
    paddingTop: '10px',
    paddingBottom: '10px'
  },
  '& .bold-first-cell td:first-child': {
    fontWeight: 'bold',
  },
});


export const WorkOrderDetails = ({ taskNumber }) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchData = async () => {
    try {
      const response = await ApiUtil.get('/hearings/transcription_work_order/display_wo_summary', {
        query: { task_number: taskNumber },
      });

      setData(response.body.data);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [taskNumber]);

  if (loading) {
    return <div>Loading...</div>;
  }

  if (error) {
    return <div>Error loading data: {error.message}</div>;
  }

  if (!data) {
    return <div>No data found</div>;
  }

  const { workOrder, returnDate, contractorName, woFileInfo } = data;

  return (
    <div className="cf-app-segment cf-app-segment--alt">
      <div>
        <h1>Work order summary #{workOrder}</h1>
        <div style={{ marginBottom: '20px' }}>
          <strong>Work order:</strong> #{workOrder}
        </div>
        <div style={{ marginBottom: '20px' }}>
          <strong>Return date:</strong> {returnDate}
        </div>
        <div style={{ marginBottom: '20px' }}>
          <strong>Contractor:</strong> {contractorName}
        </div>
      </div>
      <hr style={{ margin: '35px 0' }} />
      <div>
        <h2 className="no-margin-bottom">Number of files: {woFileInfo.length}</h2>
        <div {...styles}>
          <QueueTable
            columns={columns}
            rowObjects={woFileInfo}
            summary="Individual claim history"
            slowReRendersAreOk
            className="bold-first-cell"
          />
        </div>
      </div>
    </div>
  );
};

WorkOrderDetails.propTypes = {
  taskNumber: PropTypes.string.isRequired,
};

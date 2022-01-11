import React, { useState, useRef } from 'react';
import { CSVLink } from 'react-csv';

import ApiUtil from 'app/util/ApiUtil';
import Button from 'app/components/Button';
import { parseCSVData } from 'app/hearings/utils';

export const CSVButton = ({ startDate, endDate, view, headers, fileName }) => {
  const [values, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const ref = useRef();

  const downloadView = async (event, done) => {
    done(false);
    setLoading(true);

    const url = `/hearings/hearing_day.csv?start_date=${startDate}&end_date=${endDate}&show_all=${view}`;
    const data = await ApiUtil.get(url);
    const { hearings } = JSON.parse(data?.text);
    const result = parseCSVData(Object.values(ApiUtil.convertToCamelCase(hearings)));

    setData(result);
    setLoading(false);
    ref.current.link.click();
  };

  return (
    <React.Fragment>
      <CSVLink data={values} asyncOnClick onClick={downloadView} >
        <Button classNames={['usa-button-secondary']} disabled={loading}>
          {loading ? 'Loading csv...' : 'Download current view'}
        </Button>
      </CSVLink>
      <CSVLink ref={ref} filename={fileName} headers={headers} data={values} />
    </React.Fragment>
  );
};

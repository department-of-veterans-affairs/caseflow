import React, { useEffect, useState } from 'react';
import { CSVLink } from 'react-csv';

import ApiUtil from 'app/util/ApiUtil';
import Button from 'app/components/Button';

export const CSVButton = ({ startDate, endDate, view }) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  const downloadView = (event, done) => {
    if (!loading) {
      setLoading(true);
      const url = `/hearings/hearing_day.csv?start_date=${startDate}&end_date=${endDate}&show_all=${view}`;

      ApiUtil.get(url).then((data) => {
        setLoading(false);
        setData(data);

        // Proceed and get data from dataFromListOfUsersState function
        done(true);
      }).
        catch(() => {
          setLoading(false);
          done(false);
        });
    }
  };

  return (
    <CSVLink data={() => data} asyncOnClick onClick={downloadView} >
      {loading ? 'Loading csv...' : <Button classNames={['usa-button-secondary']}>Download current view</Button>}
    </CSVLink>
  );
}
;

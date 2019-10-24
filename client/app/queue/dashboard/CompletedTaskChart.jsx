import React from 'react';
import { ResponsiveLine } from '@nivo/line';
import PropTypes from 'prop-types';

const CompletedTaskChart = ({ data /* Data to be passed into the graph goes here */ }) => (
  <div style={{ height: 400 }}>
    <ResponsiveLine
      data={data}
      margin={{ top: 50,
        right: 110,
        bottom: 50,
        left: 60 }}
      xScale={{ type: 'point' }}
      yScale={{ type: 'linear',
        min: 'auto',
        max: 'auto' }}
      axisBottom={{
        orient: 'bottom',
        tickSize: 5,
        tickPadding: 5,
        tickRotation: 0,
        legend: 'Date',

        legendOffset: -10,

        legendPosition: 'middle'
      }}
      axisLeft={{
        orient: 'left',
        tickSize: 5,
        tickPadding: 5,
        tickRotation: 0,
        legend: 'Completed Tasks',
        legendOffset: 40,
        legendPosition: 'middle'
      }}
      pointSize={10}
      pointBorderWidth={2}
      pointLabel="y"
      pointLabelYOffset={-12}
      useMesh
      animate
    />
  </div>
);

export default CompletedTaskChart;

CompletedTaskChart.propTypes = {
  data: PropTypes.arrayOf(
    PropTypes.shape({
      date: PropTypes.date,
      taskComplete: PropTypes.number
    })
  )
};

import React from 'react';
import PropTypes from 'prop-types';
import { StatisticCard } from './StatisticCard';

import { css } from 'glamor';

const containerStyles = css({
  display: 'flex',
  justifyContent: 'space-between',
  width: '100%'
});

const cardStyles = css({
  width: '150px',
  margin: '0 10px'
});

const metrics = {
  assigned: { label: 'Assigned' },
  cancelled: { label: 'Cancelled' },
  completed: { label: 'Completed',
    color: '#2E8540' },
  on_hold: { label: 'On Hold',
    color: '#F8CC65' },
  in_progress: { label: 'In Progress',
    color: '#2771B7' }
};

export const OrganizationStatistics = ({ statistics }) => {
  const items = Object.entries(statistics);

  return (
    <div {...containerStyles}>
      {items.map(([key, val]) => (
        <StatisticCard
          key={key}
          title={metrics[key].label}
          value={val}
          icon="check"
          color={metrics[key].color}
          {...cardStyles}
        />
      ))}
    </div>
  );
};

OrganizationStatistics.propTypes = {
  statistics: PropTypes.object
};

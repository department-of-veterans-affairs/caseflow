import React from 'react';
import PropTypes from 'prop-types';
import { Card } from './Card';

import { css } from 'glamor';

const titleStyles = css({
  fontSize: '1.6rem'
});

const valueStyles = css({
  fontSize: '3.2rem'
});

export const StatisticCard = ({ title, value, icon, color, ...rest }) => (
  <Card {...rest} className="statistic-card">
    <React.Fragment>
      <h3 {...titleStyles}>{title}</h3>

      <div className="statistic-value" {...valueStyles} style={{ color }}>
        {icon && <i style={{ marginRight: '1rem' }} className="fa fa-check-circle-o" />}
        {value}
      </div>
    </React.Fragment>
  </Card>
);

StatisticCard.propTypes = {
  title: PropTypes.string,
  value: PropTypes.number,
  icon: PropTypes.string,
  color: PropTypes.string
};

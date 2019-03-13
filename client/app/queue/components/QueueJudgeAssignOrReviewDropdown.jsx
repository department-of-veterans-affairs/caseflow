import React from 'react';
import PropTypes from 'prop-types';

import QueueSelectorDropdown from './QueueSelectorDropdown';
import COPY from '../../../COPY.json';

export default class QueueJudgeAssignOrReviewDropdown extends React.Component {
  render = () => {
    const url = window.location.pathname.split('/');
    const location = url[url.length - 1];
    const reviewTo = (['review', 'queue'].includes(location)) ? '#' : `/queue/${this.props.userId}/review`;
    const assignTo = (location === 'assign') ? '#' : `/queue/${this.props.userId}/assign`;

    const items = [
      {
        key: '0',
        to: reviewTo,
        label: COPY.JUDGE_REVIEW_DROPDOWN_LINK_LABEL
      },
      {
        key: '1',
        to: assignTo,
        label: COPY.JUDGE_ASSIGN_DROPDOWN_LINK_LABEL
      }
    ];

    return <QueueSelectorDropdown items={items} />;
  }
}

QueueJudgeAssignOrReviewDropdown.propTypes = {
  userId: PropTypes.number.isRequired
};

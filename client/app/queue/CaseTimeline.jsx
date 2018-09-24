import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import { boldText } from './constants';
import { DateString } from '../util/DateUtil';
import Address from './components/Address';

const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});

export default class CaseTimeline extends React.PureComponent {
  getEventRow = ({ title, date }) => {
    return <tr key={title}>
      <td>{date}</td>
      <td>0</td>
      <td>{title}</td>
    </tr>;
  }

  render = () => {
    const { appeal } = this.props;

    const events = [
      {
        title: "Notice of disagreement received",
        date: appeal.nodReceiptDate
      },
      {
        title: "BVA Decision pending",
        date: appeal.decisionDate
      }
    ];
    return <table>
      {events.map((event) => {
        return this.getEventRow(event);
      })}
    </table>
  };
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object.isRequired
};

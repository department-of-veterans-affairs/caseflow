import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import { boldText } from './constants';
import { DateString } from '../util/DateUtil';
import Address from './components/Address';
import { GrayDot, GreenCheckmark } from '../components/RenderFunctions';
import moment from 'moment';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

const grayLine = css({
  width: '5px',
  minHeight: '50px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto'
});

const tableCellWithIcon = css({
  textAlign: 'center',
  border: 'none',
  padding: 0
});

const tableCell = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px'
});

export default class CaseTimeline extends React.PureComponent {
  getEventRow = ({ title, pendingTitle, date }, lastRow) => {
    const formattedDate = date ? moment(date).format('MM/DD/YYYY') : null;
    const eventImage = date ? <GreenCheckmark /> : <GrayDot />;

    return <tr key={title}>
      <td {...tableCell}>{formattedDate}</td>
      <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>
      <td {...tableCell}>{date ? title : pendingTitle}</td>
    </tr>;
  }

  render = () => {
    const { appeal } = this.props;

    const events = [
      {
        title: "BVA Decision made",
        pendingTitle: "BVA Decision pending",
        date: appeal.decisionDate
      },
      {
        legacyOnly: true,
        title: "Form 9 received",
        pendingTitle: "Form 9 pending",
        date: appeal.events.form9Date
      },
      {
        title: "Notice of disagreement received",
        pendingTitle: "Notice of disagreement pending",
        date: appeal.events.nodReceiptDate
      }
    ].filter((event) => !event.legacyOnly || appeal.isLegacyAppeal);

    return <table>
      {events.map((event, index) => {
        return this.getEventRow(event, index === events.length - 1);
      })}
    </table>
  };
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object.isRequired
};

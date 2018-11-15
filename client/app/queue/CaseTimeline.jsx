import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { GrayDot, GreenCheckmark } from '../components/RenderFunctions';
import moment from 'moment';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';

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
        title: COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA,
        pendingTitle: COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING,
        date: appeal.decisionDate
      },
      appeal.timeline,
      {
        legacyOnly: true,
        title: COPY.CASE_TIMELINE_FORM_9_RECEIVED,
        pendingTitle: COPY.CASE_TIMELINE_FORM_9_PENDING,
        date: appeal.events.form9Date
      },
      {
        title: COPY.CASE_TIMELINE_NOD_RECEIVED,
        pendingTitle: COPY.CASE_TIMELINE_NOD_PENDING,
        date: appeal.events.nodReceiptDate
      }
    ].flat().filter((event) => !event.legacyOnly || appeal.isLegacyAppeal);

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table>
        <tbody>
          {events.map((event, index) => {
            return this.getEventRow(event, index === events.length - 1);
          })}
        </tbody>
      </table>
    </React.Fragment>;
  };
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object.isRequired
};

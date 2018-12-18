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

const getEventRow = ({ title, date }, lastRow) => {
  const formattedDate = date ? moment(date).format('MM/DD/YYYY') : null;
  const eventImage = date ? <GreenCheckmark /> : <GrayDot />;

  return <tr key={title}>
    <td {...tableCell}>{formattedDate}</td>
    <td {...tableCellWithIcon}>{eventImage}{!lastRow && <div {...grayLine} />}</td>
    <td {...tableCell}>{title}</td>
  </tr>;
};

export const CaseTimeline = ({ appeal }) => {
  return <React.Fragment>
    {COPY.CASE_TIMELINE_HEADER}
    <table>
      <tbody>
        {appeal.timeline.map((event, index) => {
          return getEventRow(event, index === appeal.timeline.length - 1);
        })}
      </tbody>
    </table>
  </React.Fragment>;
};

CaseTimeline.propTypes = {
  appeal: PropTypes.object.isRequired
};

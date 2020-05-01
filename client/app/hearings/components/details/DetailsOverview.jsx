import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

import { listStyling, listItemStyling } from './style';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import * as DateUtil from '../../../util/DateUtil';

const Overview = ({ columns }) => (
  <div {...listStyling}>
    {columns.map((col, i) => (
      <div key={i} {...listItemStyling}>
        <h4>{col.label}</h4>
        <div>{col.value}</div>
      </div>
    ))}
  </div>
);

Overview.propTypes = {
  columns: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      value: PropTypes.any
    })
  )
};

const DetailsOverview = ({
  hearing: {
    scheduledFor,
    docketName,
    docketNumber,
    regionalOfficeName,
    readableLocation,
    disposition,
    readableRequestType,
    hearingDayId,
    aod,
    isVirtual
  }
}) => (
  <Overview
    columns={[
      {
        label: 'Hearing Date',
        value:
          readableRequestType === 'Travel' ? (
            <strong>{DateUtil.formatDateStr(scheduledFor)}</strong>
          ) : (
            <Link to={`/schedule/docket/${hearingDayId}`}>
              <strong>{DateUtil.formatDateStr(scheduledFor)}</strong>
            </Link>
          )
      },
      {
        label: 'Docket Number',
        value: (
          <span>
            <DocketTypeBadge name={docketName} number={docketNumber} />
            {docketNumber}
          </span>
        )
      },
      {
        label: 'Regional office',
        value: regionalOfficeName
      },
      {
        label: 'Hearing Location',
        value: readableLocation
      },
      {
        label: 'Disposition',
        value: disposition
      },
      {
        label: 'Type',
        value: isVirtual ? 'Virtual' : readableRequestType
      },
      {
        label: 'AOD Status',
        value: aod || 'None'
      }
    ]}
  />
);

DetailsOverview.propTypes = {
  hearing: PropTypes.shape({
    scheduledFor: PropTypes.string,
    docketName: PropTypes.string,
    docketNumber: PropTypes.string,
    regionalOfficeName: PropTypes.string,
    readableLocation: PropTypes.string,
    disposition: PropTypes.string,
    readableRequestType: PropTypes.string,
    hearingDayId: PropTypes.number,
    aod: PropTypes.bool,
    isVirtual: PropTypes.bool
  })
};

export default DetailsOverview;

import { Link } from 'react-router-dom';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import {
  TitleDetailsSubheader
} from '../../../components/TitleDetailsSubheader';
import CopyTextButton from '../../../components/CopyTextButton';
import * as DateUtil from '../../../util/DateUtil';
import { dispositionLabel } from '../../utils';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

const headerContainerStyling = css({
  margin: '-2rem 0 0 0',
  padding: '0 0 1.5rem 0',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const headerStyling = css({
  paddingLeft: 0,
});

export const DetailsHeader = (
  {
    aod,
    disposition,
    docketName,
    docketNumber,
    isVirtual,
    hearingDayId,
    readableLocation,
    readableRequestType,
    regionalOfficeName,
    scheduledFor,
    veteranFirstName,
    veteranLastName,
    veteranFileNumber
  }
) => {
  const columns = [
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
      value: dispositionLabel(disposition)
    },
    {
      label: 'Type',
      value: isVirtual ? 'Virtual' : readableRequestType
    },
    {
      label: 'AOD Status',
      value: aod || 'None'
    }
  ];

  return (
    <React.Fragment>
      <div {...headerContainerStyling}>
        <h1 className="cf-margin-bottom-0" {...headerStyling}>
          {`${veteranFirstName} ${veteranLastName}'s Hearing Details`}
        </h1>
        <div>
          Veteran ID: <CopyTextButton text={veteranFileNumber} label="Veteran ID" />
        </div>
      </div>

      <TitleDetailsSubheader columns={columns} />
    </React.Fragment>
  );
};

DetailsHeader.propTypes = {
  aod: PropTypes.bool,
  disposition: PropTypes.string,
  docketName: PropTypes.string,
  docketNumber: PropTypes.string,
  isVirtual: PropTypes.bool,
  hearingDayId: PropTypes.number,
  readableLocation: PropTypes.string,
  readableRequestType: PropTypes.string,
  regionalOfficeName: PropTypes.string,
  scheduledFor: PropTypes.string,
  veteranFirstName: PropTypes.string,
  veteranLastName: PropTypes.string,
  veteranFileNumber: PropTypes.string
};

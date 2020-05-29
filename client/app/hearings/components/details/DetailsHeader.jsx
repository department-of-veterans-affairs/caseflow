import { css } from 'glamor';
import React from 'react';

import {
  TitleDetailsSubheader,
} from '../../../components/TitleDetailsSubheader';
import CopyTextButton from '../../../components/CopyTextButton';

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
  paddingRight: '2.5rem'
});

export const DetailsHeader = (
  { veteranFirstName, veteranLastName, veteranFileNumber, columns }
) => (
  <React.Fragment>
    <div {...headerContainerStyling}>
      <h1 className="cf-margin-bottom-0" {...headerStyling}>
        {`${veteranFirstName} ${veteranLastName}`}
      </h1>
      <div>
        Veteran ID: <CopyTextButton text={veteranFileNumber} label="Veteran ID" />
      </div>
    </div>

    <TitleDetailsSubheader columns={columns} />
  </React.Fragment>
);

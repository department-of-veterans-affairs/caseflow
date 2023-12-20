import React from 'react';
import { css } from 'glamor';

import { cavcUrl } from '.';
import CopyTextButton from '../../components/CopyTextButton';

const btnWrapStyles = css({
  display: 'inline-block',
  lineHeight: '3em'
});

export const CavcLinkInfo = () => (
  <div>
    Copy and paste the CAVC website link into Internet Explorer:{' '}
    <div {...btnWrapStyles}>
      <CopyTextButton text={new URL(cavcUrl).hostname} textToCopy={cavcUrl} label="uscourts.cavc.gov" />
    </div>
  </div>
);

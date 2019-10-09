import React from 'react';

import { cavcUrl } from '.';
import CopyTextButton from '../components/CopyTextButton';

export const CavcLinkInfo = () => (
  <div>
    Copy and paste the CAVC website link into Internet Explorer{' '}
    <CopyTextButton text={new URL(cavcUrl).hostname} textToCopy={cavcUrl} label="uscourts.cavc.gov" />
  </div>
);

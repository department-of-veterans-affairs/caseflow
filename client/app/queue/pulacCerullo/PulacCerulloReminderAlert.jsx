import React from 'react';
import Alert from '../../components/Alert';
import { CavcLinkInfo } from './CavcLinkInfo';

export const PulacCerulloReminderAlert = () => {
  return (
    <Alert type="warning" title="Check CAVC for conflict of jurisdiction">
      <CavcLinkInfo />
      <div>
        <i>Note: The CAVC website is not compatible with Chrome.</i>
      </div>
      <p>
        If there is a Notice of Appeal (NOA) on file at the CAVC website, use the Actions Menu to notify Litigation
        Support.
      </p>
    </Alert>
  );
};
PulacCerulloReminderAlert.propTypes = {};

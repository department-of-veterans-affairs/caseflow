import React from 'react';
import Alert from '../../components/Alert';
import { chairmanMemoUrl } from '.';
import { CavcLinkInfo } from './CavcLinkInfo';

export const PulacCerulloReminderAlert = () => {
  return (
    <Alert type="warning" title="Check CAVC for conflict of jurisdiction">
      <p>Please make certain that there are no impediments to working on this case.</p>
      <p>
        If this decision has a Notice of Appeal (NOA) on file at the CAVC website, use the Actions menu to notify
        Litigation Support.
        <br />
        <i>
          Note for Chrome users: The CAVC website is only compatible with Internet Explorer; contact Litigation Support
          if you encounter any errors.
        </i>
      </p>
      <p>
        See{' '}
        <a href={chairmanMemoUrl} target="_blank" rel="noopener noreferrer">
          Chairman's Memorandum No. 01-10-18
        </a>{' '}
        for more information about how to conduct NOA checks.
      </p>
      <CavcLinkInfo />
    </Alert>
  );
};
PulacCerulloReminderAlert.propTypes = {};

import React from 'react';
import QueueOrganizationDropdown from '../../queue/components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import TabWindow from '../../components/TabWindow';
import COPY from '../../../COPY';

export const TranscriptionFileDispatchPage = () => {
  const tabList = [
    COPY.CASE_LIST_TABLE_UNASSIGNED_LABEL,
    COPY.TRANSCRIPTION_DISPATCH_ASSIGNED_TAB,
    COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
    COPY.TRANSCRIPTION_DISPATCH_ALL_TAB
  ];
  const tabConfig = (labels) => labels.map((label) => ({ label, page: <React.Fragment /> }));

  return (
    <AppSegment filledBackground>
      <h1 {...css({ display: 'inline-block' })}>Transcription file dispatch</h1>
      <QueueOrganizationDropdown organizations={[{ name: 'Transcription', url: 'transcription-team' }]} />
      <TabWindow
        name="transcription-tabwindow"
        defaultPage={0}
        fullPage={false}
        tabs={tabConfig(tabList)}
      />
    </AppSegment>
  );
};

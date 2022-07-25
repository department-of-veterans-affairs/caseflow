import React from 'react';
import { css } from 'glamor';

import QueueFlowPage from '../components/QueueFlowPage';
import SplitAppealProgressBar from './SplitAppealProgressBar';

import COPY from '../../../COPY.json';

const SplitAppealView = (props) => {
  console.log(props);

  return (
    <>
      <SplitAppealProgressBar />
      <QueueFlowPage>
        <h1>{COPY.SPLIT_APPEAL_CREATE_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_CREATE_SUBHEAD}</span>

        
      </QueueFlowPage>
    </>
  );
};

export default SplitAppealView;

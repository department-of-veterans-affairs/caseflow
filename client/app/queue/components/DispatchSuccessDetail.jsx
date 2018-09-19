// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import COPY from '../../../COPY.json';
import type { Task } from '../types/models';

type Params = {|
  task: Task
|};

type Props = Params & {|
  feedbackUrl: string
|};

const DispatchSuccessDetail = (props: Props) => {
  const {
    task,
    feedbackUrl
  } = props;

  if (task.appealType === 'LegacyAppeal') {
    return COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_LEGACY;
  }
  return <React.Fragment>
    {COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_AMA_BEFORE_LINK}
    <a href={feedbackUrl}>{COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_AMA_LINK}</a>
    {COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_AMA_AFTER_LINK}
  </React.Fragment>;
}

export default (connect((state) => { feedbackUrl: 'https://google.com' })(DispatchSuccessDetail): React.ComponentType<Params>);

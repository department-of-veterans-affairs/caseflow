// @flow
import * as React from 'react';
import { css } from 'glamor';

const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});

import type { Issue } from '../types/models';

type Props = {
  issue: Issue,
  idx: number
};

const IssueListItem = (props: Props) => <React.Fragment>
  <td {...leftAlignTd} width="10px">
    {props.idx}
  </td>
  <td {...minimalLeftPadding}>
    {props.issue.description}
  </td>
</React.Fragment>;

export default IssueListItem;

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import DropdownButton from '../components/DropdownButton';
import moment from 'moment';
import { css } from 'glamor';

const rowHasExpandedNote = css({
  '> td': { border: 'none' },
});

const expandedNote = css({
  '> td': { borderTop: 'none' },
});

// const rowHasExpandedNote2 = $('& td', { border: 'none' });

// This is a one off component that doesn't reuse any existing components
const MembershipRequestTableV1 = (props) => {
  // TODO: Retrieve these from the backend MembershipRequests for the current org
  // const testTime = new Date().toLocaleDateString();
  // const rowObjects=[{ name: 'test 1', createdAt: testTime, note: 'This is an example reason of things and stuff.' },
  // { name: 'test 2', createdAt: testTime, note: null }];

  const { requests } = props;

  return <>
    <h2> Completely new custom one-off component</h2>
    <table className="usa-table-borderless">
      <thead>
        <tr>
          <th>User name</th>
          <th>Date requested</th>
          <th>Actions</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        {requests.map((request, index) => <CollapsableTableRow key={index} request={request} />)}
      </tbody>
    </table>
  </>;
};

const CollapsableTableRow = (props) => {
  const [expanded, setExpanded] = useState(false);

  const { request } = props;

  // TODO: Build this out for each request since the target will be based on the id for the MembershipRequest
  // At least, I think that's how it might work later.
  const dropdownOptions = [
    {
      title: 'Approve',
      target: '/approve' },
    {
      title: 'Deny',
      target: '/deny' }
  ];

  return [
    <tr className={expanded ? `${rowHasExpandedNote}` : ''}>
      <td>{request.name}</td>
      <td>{moment(request.requestedDate).format('MM/DD/YYYY')}</td>
      <td>
        <DropdownButton
          lists={dropdownOptions}
          // onClick={this.handleMenuClick}
          label="Select action"
        />
      </td>
      <td>
        {request.note ?
          <button style={{ backgroundColor: 'inherit' }}
            className="usa-accordion-button"
            aria-expanded={expanded}
            onClick={() => setExpanded(!expanded)}>
          </button> :
          ''}
      </td>
    </tr>,
    expanded && (
      <tr className={expanded ? expandedNote : ''} aria-expanded={expanded}>
        <td colSpan={4}>
          <strong>REQUEST NOTE:</strong>
          <p>{request.note}</p>
        </td>
      </tr>
    )
  ];
};

MembershipRequestTableV1.propTypes = {
  requests: PropTypes.array,
};

export default MembershipRequestTableV1;

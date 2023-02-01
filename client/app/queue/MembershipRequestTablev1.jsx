import React, { useState } from 'react';
import DropdownButton from '../components/DropdownButton';

// This is a one off component that doesn't reuse any existing components
const MembershipRequestTableV1 = (props) => {
  // TODO: Retrieve these from the backend MembershipRequests for the current org
  const testTime = new Date().toLocaleDateString();
  const rowObjects = [{ name: 'test 1', createdAt: testTime, note: 'This is an example reason of things and stuff.' },
    { name: 'test 2', createdAt: testTime, note: null }];

  return <table className="usa-table-borderless">
    <thead>
      <th>User name</th>
      <th>Date requested</th>
      <th>Actions</th>
      <th></th>
    </thead>
    <tbody>
      {rowObjects.map((rowObject, index) => <CollapsableTableRow key={index} request={rowObject} />)}
    </tbody>
  </table>;
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
    <tr>
      <td>{request.name}</td>
      <td>{request.createdAt}</td>
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
      <tr aria-expanded={expanded}>
        <td colSpan={4}>
          <strong>Request note:</strong>
          <p>{request.note}</p>
        </td>
      </tr>
    )
  ];
};

export default MembershipRequestTableV1;

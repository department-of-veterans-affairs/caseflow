import React, { useState } from 'react';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';

const MembershipRequestTableV2 = () => {

  const rowObjects = () => {
    return [];
  };

  const columnDefinitions = () => {
    return [];
  };

  return <>
    <Table columns={columnDefinitions} rowObjects={rowObjects} />
  </>;
};

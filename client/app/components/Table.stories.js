import React from 'react';
import { concat } from 'lodash';

import Table from './Table';

const columns = [
  {
    header: 'Name',
    valueName: 'name',
    footer: 'Totals'
  },
  {
    header: 'Favorite Animal',
    align: 'center',
    valueName: 'favoriteAnimal',
    footer: '3'
  },
  {
    header: 'Likes sports?',
    align: 'center',
    valueFunction: (person) => {
      return person.likesSports ? 'Yes' : 'No';
    },
    footer: '1'
  }
];

const columnsWithAction = _.concat(columns, [
  {
    header: 'Poke',
    align: 'right',
    valueFunction: (person, rowNumber) => {
      return <a href={`#poke-${rowNumber}`}>Poke {person.name} »</a>;
    }
  }
]);

const rowObjects = [
  {
    name: 'Shane',
    favoriteAnimal: 'Hamster',
    likesSports: true
  },
  {
    name: 'Kavi',
    favoriteAnimal: 'Koala Bear',
    likesSports: false
  },
  {
    name: 'Gina',
    favoriteAnimal: 'Otter',
    likesSports: false
  }
];

export default {
  title: 'Commons/Components/Table',
  component: Table,
};

export const Minimal = (args) => <Table {...args} />;
Minimal.args = {
  columns,
  rowObjects,
  summary: 'Example minimal table',
  slowReRendersAreOk: true
};

export const Basic = (args) => {
  const setRowClassNames = (rowObject) => {
    return rowObject.likesSports ? 'cf-success' : '';
  };

  return <Table {...args} rowClassNames={setRowClassNames} />;
};
Basic.args = {
  columns,
  rowObjects,
  summary: 'Example table',
  slowReRendersAreOk: true
};
Basic.parameters = {
  docs: {
    description: {
      story:
      `We use tables to display information across Caseflow. Most frequently they are used in users Queues but we
      sometimes use them to help users accomplish a specific task. For aesthetic purposes, tables in Caseflow are
      borderless.<br><br> Table headings should be bold and with a white background.<br><br> Often tables will contain
      an primary action a user can take on the table item. These actions should always be placed in the right most
      column of the table and should be right aligned with the edge of the table.`
    },
  },
};

export const Queue = (args) => <Table {...args} />;
Queue.args = {
  columns: columnsWithAction,
  rowObjects,
  summary: 'Example queue table',
  slowReRendersAreOk: true
};
Queue.parameters = {
  docs: {
    description: {
      story:
        `Tables are most frequently used in users' Queues or a list of work items for a user to take action on. Queues
        are shown in the standard App Canvas as tables. A distinct feature of queue tables is the right-aligned
        actionable link, such as "Assign >>," located on the far right column.`
    },
  },
};

import React from 'react';
import _ from 'lodash';

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
}

export const Queue = (args) => <Table {...args} />
Queue.args = {
  columnsWithAction, //doesn't work
  //columns, //works
  rowObjects,
  summary: 'Example queue table',
  slowReRendersAreOk: true
}

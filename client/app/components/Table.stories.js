import React from 'react';

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

const Template = (args) => {

  const setRowClassNames = (rowObject) => {
    return rowObject.likesSports ? 'cf-success' : '';
  };

  return <Table {...args} rowClassNames={setRowClassNames} />;
};

export const Basic = Template.bind({});
Basic.args = {
  columns,
  rowObjects,
  summary: 'Example styleguide table',
  slowReRendersAreOk: true
}

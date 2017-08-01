import React from 'react';
import _ from 'lodash';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

// components
import Table from '../../components/Table';
import { ChervonDown, ChervonUp } from '../../components/RenderFunctions';
import Button from '../../components/Button';

export default class StyleGuideExpandaleTables extends React.Component {
  // constructor(props) {
  //   super(props);
    
  //   this.icons = {
  //     'up' : <ChervonUp />, 
  //     'down' : <ChervonDown />
  //   };
  //   this.state ={
  //     expanded: true
  //   };
  // }
render = () => {
  // List of objects which will be used to create each row
  let rowObjects = [
    { name: 'Marian',
      dateofbirth: '07/04/1776',
      likesIceCream: true },
    { name: 'Shade',
      dateofbirth: '04/29/2015',
      likesIceCream: true },
    { name: 'Teja',
      dateofbirth: '06/04/1919',
      likesIceCream: true },
      { name: 'Gina',
      dateofbirth: '04/23/1564',
      likesIceCream: false }
  ];

  let columns = [
    {
      header: 'Name',
      valueName: 'name',
    },
    {
      header: 'Date of Birth',
      align: 'center',
      valueName: 'dateofbirth',
    },
    {
      header: 'Likes icecream?',
      align: 'center',
      valueFunction: (person) => {
        return person.likesIceCream ? 'Yes' : 'No';
      }
    }
  ];

  let rowClassNames = (rowObject) => {
    return rowObject.likesIceCream ? 'cf-success' : '';
  };

  let columnsWithAction = _.concat(columns, [
    {
      header: 'Details',
      align: 'right',
      valueFunction: (person, rowNumber) => {
        return <Button
         classNames={['cf-btn-link']}
         name="See more"
         href={`#details-${rowNumber}`}
         />
      }
    }
  ]);

  let summary = 'Example styleguide table';

  return <div className="cf-sg-tables-section">
    <StyleGuideComponentTitle
      title="Expandable Tables"
      id="table"
      link="StyleGuideExpanableTables.jsx"
      isSubsection={true}
    />
    <div className="cf-push-right">
    <Button
      name="Expand all"
      />
    </div>

    <Table columns={columnsWithAction} rowObjects={rowObjects} summary={summary} slowReRendersAreOk={true}/>
  </div>;
 }
}
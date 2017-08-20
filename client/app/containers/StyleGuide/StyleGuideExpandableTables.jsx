import React from 'react';
import _ from 'lodash';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

// components
import Table from '../../components/Table';
import Button from '../../components/Button';
import { ChevronDown, ChevronUp } from '../../components/RenderFunctions';


export default class StyleGuideExpandaleTables extends React.Component {
  constructor(props) {
    super(props);

    this.state ={
     expanded: true
   };
}

  handleClick() {
    this.setState(prevState => ({
      expanded: !prevState.expanded
    }));
  }

render = () => {

  const name = 'See more';
  const sortedIcon = <ChevronUp />;
  const notsortedIcon = <ChevronDown />;

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
      valueFunction: () => {
        return 
          <Button 
            classNames={['cf-btn-link']}
            name={name}
            onClick={this.handleClick}> See More
            {this.state.expanded ? sortedIcon : notsortedIcon}
            </Button>;
      }
    }
  ]);


 let summary = 'Example styleguide table';

 return <div className="cf-sg-tables-section">
  <StyleGuideComponentTitle
     title="Expandable Tables"
      id="expandable_table"
      link="StyleGuideExpanableTables.jsx"
    />

    <h3>Table accordion</h3>
    <p>
      The table accordion was initially designed for Caseflow Reader to allow
      users to see additional information of a specific section. 
      Many times the length of content can break the balance of design 
      and we want to make sure we capture the most important elements in a row. 
      This design cues users to expand a view so that they have enough context 
      to know what to expect.
    </p>

    <div className="cf-push-right">
    <Button
      name="Expand all"
      />
    </div>

    <Table columns={columnsWithAction} rowObjects={rowObjects} summary={summary} slowReRendersAreOk={true}/>
  </div>;
  }
}

import React from 'react';
import _ from 'lodash';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
// components
import Table from '../../components/Table';
import ToggleButton from '../../components/ToggleButton';
import Button from '../../components/Button';
import { ChevronDown, ChevronUp } from '../../components/RenderFunctions';
import Comment from './../../components/Comment';

export default class StyleGuideExpandaleTables extends React.Component {
  constructor(props) {
    super(props);

    this.state ={
     expanded: true,
     active: 'expand1'
   };
}

  handleClick = () => {
    this.setState({
      expanded: !this.state.expanded
    });
  }


  menuClick = (name) => {
    this.setState({ active: name });
  }

render = () => {
  const NUMBER_OF_COLUMNS = 4;

  const commentIcons = this.state.expanded ? <ChevronUp /> : <ChevronDown />;

  // List of objects which will be used to create each row
  let rowObjects = [
    { name: 'Marian',
     dateofbirth: '07/04/1776',
      likesIceCream: true
      },
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

  
  let columnsWithAction = _.concat(columns, [
    {
      header: 'Details',
      align: 'center',
      valueFunction: () => {
        return (
          <Button 
            classNames={['cf-btn-link']}
            href="#"
            name="See_more"
            onClick={this.handleClick}>See more
            <span className="cf-table-left">
            {commentIcons}
            </span>
          </Button>
        )
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
    <ToggleButton active={this.state.active}
       onClick={this.menuClick}>
      <Button
       name="expand1">
       Expand all
      </Button>
      <Button
       name="expand2">
       Collapse all
      </Button>
     </ToggleButton>
     </div>

    <Table 
    columns={columnsWithAction} 
    rowObjects={rowObjects} 
    summary={summary} 
    slowReRendersAreOk={true}
    />
  </div>;
  }
}

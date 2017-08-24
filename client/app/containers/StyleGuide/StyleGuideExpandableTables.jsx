import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
// components
import Table from '../../components/Table';
import ToggleButton from '../../components/ToggleButton';
import Button from '../../components/Button';
import { ChevronDown, ChevronUp } from '../../components/RenderFunctions';


export default class StyleGuideExpandaleTables extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
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

  commentIcons = (expanded) => expanded ? <ChevronUp /> : <ChevronDown />;


  getColumns = (row) => {

    if (row && row.expandable) {
      return [
        {
          header: 'Name',
          valueName: 'name',
          span: () => {
            return 4;
          }
        }];
    }

    return [
      {
        header: 'Name',
        valueName: 'name'
      },
      {
        header: 'Date of Birth',
        align: 'center',
        valueName: 'dateofbirth'
      },
      {
        header: 'Likes icecream?',
        align: 'center',
        valueFunction: (person) => {
          return person.likesIceCream ? 'Yes' : 'No';
        }
      },
      {
        header: 'Details',
        align: 'center',
        valueFunction: (person, rowNumber) => {
          return <span className="document-list-comments-indicator">
           <Button
            classNames={['cf-btn-link']}
            href={`#details-${rowNumber}`}
            name="See_more"
            onClick={this.handleClick}>See more
            <span className="cf-table-left">
            {this.commentIcons(this.state.expanded)}
            </span>
          </Button>
         </span>;
        }
      }
    ];

  }
  render = () => {

  // List of objects which will be used to create each row
    let rowObjects = [
      { name: 'Marian',
        dateofbirth: '07/04/1776',
        likesIceCream: true
      },
      { name: 'Marian Likes mint Chocolate ice cream',
        expandable: true
      },
      { name: 'Shade',
        dateofbirth: '04/29/2015',
        likesIceCream: true },
      { name: 'Shade likes jazzy peanut butter ice cream with extra hot fudge.',
        expandable: true
      },
      { name: 'Teja',
        dateofbirth: '06/04/1919',
        likesIceCream: true },
      { name: 'Teja used to work at an ice cream shop and got very sick of it smelling dairy....',
        expandable: true
      },
      { name: 'Gina',
        dateofbirth: '04/23/1564',
        likesIceCream: false },
      { name: 'Gina is lactose intolerant. It is very unfortunate.',
        expandable: true }
    ];

    // let expandableComment = () => {
    //   return <div className="comment-horizontal-container">
    //   <div className="horizontal-comment">
    //     <div className="comment-content">
    //       {row.expandable}
    //     </div>
    //   </div>
    // </div>;
    // };

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
    columns={this.getColumns}
    rowObjects={rowObjects}
    summary={summary}
    slowReRendersAreOk={true}
    />
  </div>;
  }
}

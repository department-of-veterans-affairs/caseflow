import React, { PropTypes } from 'react';

/**
 * This component can be used to easily build tables.
 * There required props are:
 * - @headers {array[string]} array of strings placed in <th/> tags
 * as the table header
 * - @values {array[object]} array of objects used to build the <tr/> rows
 * @buildRowValues {function} function that takes one of the `values` objects
 * and returns a new array of strings. These string values are inserted into <td/>
 * to build the row's cells
 *  e.g:  buildRowValues(taskObject) => ['cell 1 value', 'call 2 value',...]
 *
*/
export default class TabWindow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentPage: 0
    };
  }

  onTabClick = (tabNumber) => (event) => {
    this.setState({
      currentPage: tabNumber
    });
  }

  render() {
    let {
      tabs,
      pages
    } = this.props;

    return <div>
        <div className="cf-tab-navigation">
          {tabs.map((tab, i) =>
            <div
              className={`cf-tab${i === this.state.currentPage ? " cf-active" : ""}`}
              key={i}
              onClick={this.onTabClick(i)}>
              {tab}
            </div>
          )}
        </div>
        <div className="cf-tab-content">
          {pages[this.state.currentPage]}
        </div>
      </div>;
  }
}

TabWindow.propTypes = {
  tabs: PropTypes.arrayOf(PropTypes.string).isRequired,
  pages: PropTypes.arrayOf(PropTypes.node).isRequired
};

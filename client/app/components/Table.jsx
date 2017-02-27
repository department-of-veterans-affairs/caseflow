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
export default class Table extends React.Component {
  render() {
    let {
      buildRowValues,
      footers,
      headers,
      values
    } = this.props;

    return <table
      className="usa-table-borderless cf-table-borderless"
      summary="list of tasks">
      <thead>
        <tr>
          {headers.map((header, i) =>
            <th scope="col" key={i} className={this.props.columnClasses[i] || ""}>
              <h3>{header}</h3>
            </th>
          )}
        </tr>
      </thead>

      <tbody>
        {values.map((object, j) =>
          <tr id={object.id || `table-row-${j}`} key={j}>
            {buildRowValues(object, j).map((value, k) =>
              <td key={k} className={this.props.columnClasses[k] || ""}>{value}</td>
            )}

          </tr>
        )}
      </tbody>

      {footers && <tfoot>
        <tr>
          {footers.map((foot, i) =>
            <td key={`foot${i}`} className={this.props.columnClasses[i] || ""}>
              {foot}
            </td>)}
        </tr>
      </tfoot>}
    </table>;
  }
}

Table.defaultProps = {
  columnClasses: []
};

Table.propTypes = {
  buildRowValues: PropTypes.func.isRequired,
  columnClasses: PropTypes.arrayOf(PropTypes.string),
  footers: PropTypes.arrayOf(PropTypes.node),
  headers: PropTypes.arrayOf(PropTypes.node).isRequired,
  values: PropTypes.arrayOf(PropTypes.object).isRequired
};

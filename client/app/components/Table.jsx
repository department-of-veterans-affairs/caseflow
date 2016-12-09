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
      headers,
      values
    } = this.props;

    return <table className="usa-table-borderless" summary="list of tasks">
      <thead>
        <tr>
          {headers.map((header, i) =>
            <th scope="col" key={i}>
              <h3>{header}</h3>
            </th>
          )}
        </tr>
      </thead>

      <tbody>
        {values.map((object, j) =>
          <tr id={object.id} key={j}>

            {buildRowValues(object).map((value, k) =>
              <td key={k}>{value}</td>
            )}

          </tr>
        )}
      </tbody>
    </table>;
  }
}


Table.propTypes = {
  buildRowValues: PropTypes.func.isRequired,
  headers: PropTypes.arrayOf(PropTypes.string).isRequired,
  values: PropTypes.arrayOf(PropTypes.object).isRequired
};

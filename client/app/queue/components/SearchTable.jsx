import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';

import QueueTable from '../../queue/QueueTable';

import RadioField from 'app/components/RadioField';
import { setSavedParams } from '../../nonComp/actions/savedSearchSlice';

export const SearchTable = ({ eventRows, searchPageApiEndpoint }) => {
  const dispatch = useDispatch();
  const value = useSelector((state) => state.savedSearch.row.id);
  const onChange = (row) => {
    dispatch(setSavedParams(row));
  };

  const columns = [
    {
      name: '',
      header: '',
      valueFunction: (row) => <RadioField
        name={`row-${row.id}`}
        options={[{ value: row.id }]}
        hideLabel
        strongLabel
        value={value}
        // onChange={onChange}
        onChange={(val) => onChange(row, val)}
        vertical
      />
    },
    { name: 'searchName',
      header: 'Search Name',
      columnName: 'searchName',
      getSortValue: (row) => row.name,
      valueName: 'name',
      valueFunction: (row) => row.name,
    },
    { name: 'savedDate',
      header: 'Saved Date',
      columnName: 'savedDate',
      getSortValue: (row) => row.createdAt,
      valueName: 'createdAt',
      valueFunction: (row) => row.createdAt,
    },
    { name: 'admin',
      header: 'Admin',
      columnName: 'Admin',
      getSortValue: (row) => row.userCssId,
      valueName: 'userCssId',
      valueFunction: (row) => row.userCssId,
    },
    { name: 'searchDescription',
      header: 'Search Description',
      columnName: 'searchDescription',
      valueName: 'description',
      valueFunction: (row) => row.description
    }
  ];

  return (<QueueTable
    id="saved_search_table"
    columns={columns}
    rowObjects={eventRows}
    useTaskPagesApi={false}
    enablePagination
    casesPerPage={10}
    taskPageApiEndpoint={searchPageApiEndpoint}
    defaultSort= {{
      sortColName: 'savedDate',
      sortAscending: false
    }}
  />);
};

SearchTable.propTypes = {
  eventRows: PropTypes.array,
  searchPageApiEndpoint: PropTypes.string,
};

export default SearchTable;

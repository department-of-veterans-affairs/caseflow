import React from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import QueueTable from '../../queue/QueueTable';
import RadioField from 'app/components/RadioField';
import { selectSavedSearch } from '../../nonComp/actions/savedSearchSlice';

export const SearchTable = ({ eventRows, searchPageApiEndpoint }) => {
  const dispatch = useDispatch();
  const onSavedSearchChange = (row) => {
    dispatch(selectSavedSearch(row));
  };

  const columns = [
    {
      ariaLabel: 'Select search column',
      valueFunction: (row) => <RadioField
        name="savedSearchRadioFieldGroup"
        label="Select search"
        options={[{ value: row.id.toString() }]}
        hideLabel
        onChange={() => onSavedSearchChange(row)}
        vertical
      />
    },
    { name: 'searchName',
      header: 'Search Name',
      getSortValue: (row) => row.name,
      valueFunction: (row) => row.name,
    },
    { name: 'savedDate',
      header: 'Saved Date',
      getSortValue: (row) => row.createdAt,
      valueFunction: (row) => row.createdAt,
    },
    { name: 'admin',
      header: 'Admin',
      getSortValue: (row) => row.userCssId,
      valueFunction: (row) => row.userCssId,
    },
    { name: 'description',
      header: 'Description',
      valueFunction: (row) => row.description
    }
  ];

  // getKeyForRow = (index, task) => task.id

  return (<QueueTable
    id="saved_search_table"
    columns={columns}
    rowObjects={eventRows}
    useTaskPagesApi={false}
    enablePagination
    casesPerPage={15}
    getKeyForRow={(index) => index}
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

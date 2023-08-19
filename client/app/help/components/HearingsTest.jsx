import React, { useState } from 'react';
import { useQuery, gql } from '@apollo/client';

import ApiUtil from 'app/util/ApiUtil';
import Button from 'app/components/Button';

const HearingsTest = () => {
  const [restValue, setRestValue] = useState('');
  const [graphqlValue, setGraphqlValue] = useState('');

  const { data, refetch } = useQuery(gql`
      {
        hearing(id: 1)
        {
          id,
          appeal{
            id,
            docketType,
            streamDocketNumber
          }
        }
      }
    `);

  const HEARING_DAY_ID = 30;

  const performRestRequest = () => {
    const requestUrl = `/hearings/hearing_day/${HEARING_DAY_ID}`;

    return ApiUtil.get(requestUrl).then((response) => {
      setRestValue(JSON.stringify(response.body));
    });
  };

  const performGraphQLRequest = () => {
    refetch();

    setGraphqlValue(JSON.stringify(data));
  };

  const requestTypes = [
    {
      name: 'REST',
      time: '',
      value: restValue,
      requestMethod: performRestRequest
    },
    {
      name: 'GraphQL',
      time: '',
      value: graphqlValue,
      requestMethod: performGraphQLRequest
    }
  ];

  return (
    <table>
      <tbody className="query-test-table">
        {requestTypes.map((reqType) =>
          <tr>
            <td>
              <h3>{reqType.name}</h3>
            </td>
            <td>
              <Button
                name={`start-${reqType.name}-query`}
                onClick={reqType.requestMethod}
              >
                Start {reqType.name} Request
              </Button>
            </td>
            <td>
              {reqType.value}
            </td>
            <td>
              Time
            </td>
          </tr>
        )}
      </tbody>
    </table>
  );
};

export default HearingsTest;

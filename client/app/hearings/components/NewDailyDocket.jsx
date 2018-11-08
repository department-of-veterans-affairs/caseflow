import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Table from '../../components/Table';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import { DISPOSITION_OPTIONS } from '../../hearings/constants/constants';


export class DocketHearingRow extends React.PureComponent {

}
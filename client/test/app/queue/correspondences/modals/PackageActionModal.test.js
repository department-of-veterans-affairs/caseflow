import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import PackageActionModal from '../../../../../app/queue/correspondence/modals/PackageActionModal';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';
import { correspondenceData, packageDocumentTypeData, veteranInformation } from '../../../../data/correspondence';

jest.mock('react-router', () => ({
  useHistory: () => ({
    push: jest.fn()
  })
}));

const mockCloseHandler = jest.fn();
let initialState = {
  reviewPackage: {
    correspondence: correspondenceData,
    packageDocumentType: packageDocumentTypeData,
    veteranInformation
  }
};

const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

const renderPackageActionModal = (dropdownType) => {
  render(
    <Provider store={store}>
      <PackageActionModal packageActionModal={dropdownType} closerhandler={mockCloseHandler} />
    </Provider>
  );
};

describe('PackageActionModal rendering', () => {
  it('renders the remove package action modal', () => {
    const firstName = veteranInformation.veteran_name.first_name.toString();
    const lastName = veteranInformation.veteran_name.last_name.toString();
    const fileNumber = veteranInformation.file_number.toString();

    renderPackageActionModal('removePackage');

    expect(screen.getByText('Request package removal')).toBeInTheDocument();
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText('Provide a reason for removal')).toBeInTheDocument();
    expect(screen.getByText(correspondenceData.cmp_packet_number.toString())).toBeInTheDocument();
    expect(screen.getByText(packageDocumentTypeData.name)).toBeInTheDocument();
    // hacky way to match multi line dynamic text
    expect(screen.getByText(`${firstName} ${lastName}`, { exact: false })).toBeInTheDocument();
    expect(screen.getByText(`${fileNumber}`, { exact: false })).toBeInTheDocument();

    expect(screen.getByRole('button', { name: 'Confirm request' })).toBeDisabled();
    const textbox = screen.getByRole('textbox', { name: 'Provide a reason for removal' });

    userEvent.type(textbox, 'very good reason haha');
    expect(screen.getByRole('button', { name: 'Confirm request' })).not.toBeDisabled();

  });

  it('renders the reassign package action modal', () => {
    const firstName = veteranInformation.veteran_name.first_name.toString();
    const lastName = veteranInformation.veteran_name.last_name.toString();
    const fileNumber = veteranInformation.file_number.toString();

    renderPackageActionModal('reassignPackage');

    expect(screen.getByText('Request package assignment')).toBeInTheDocument();
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText('Provide a reason for reassignment')).toBeInTheDocument();
    expect(screen.getByText(correspondenceData.cmp_packet_number.toString())).toBeInTheDocument();
    expect(screen.getByText(packageDocumentTypeData.name)).toBeInTheDocument();
    // hacky way to match multi line dynamic text
    expect(screen.getByText(`${firstName} ${lastName}`, { exact: false })).toBeInTheDocument();
    expect(screen.getByText(`${fileNumber}`, { exact: false })).toBeInTheDocument();

    expect(screen.getByRole('button', { name: 'Confirm request' })).toBeDisabled();
    const textbox = screen.getByRole('textbox', { name: 'Provide a reason for reassignment' });

    userEvent.type(textbox, 'very good reason haha');
    expect(screen.getByRole('button', { name: 'Confirm request' })).not.toBeDisabled();

  });
});

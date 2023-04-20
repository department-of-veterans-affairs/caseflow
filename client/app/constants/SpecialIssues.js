import React from 'react';

// Fields:
// node:                     first choice display name; has html
// display:                  fallback plaintext display name
// queueDisplay:             fallback plaintext display name, only in Queue
// specialIssue:             React's ID
// stationOfJurisdiction:    Can be null, Regional, or this hash. ?rerouting magic at dispatch?
// {
//   key:                    ?Does some rerouting magic at Dispatch
//   location:               ?Does some rerouting magic at Dispatch
// },
// snakeCase:                Rails' ID
// unhandled: {
//   emailAddress:           ?Does some rerouting magic at Dispatch
//   regionalOffice:         ?Does some rerouting magic at Dispatch
// },
// nonCompensation:          ?Not used
// queueSection:             for Queue display, which section it goes in
// queueSectionOrder:        for Queue display, the order to display
// isAmaRelevant:            whether issue is relevant to AMA cases

// # Note: If the `snakeCase` field here is changed or added for LegacyAppeals, they must also be changed in app/models/legacy_appeal.rb SPECIAL_ISSUES const
export const SPECIAL_ISSUES = [
  {
    display: 'Contaminated Water at Camp LeJeune',
    queueDisplay: 'Contaminated water at Camp LeJeune',
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: {
      key: '327',
      location: 'Louisville, KY'
    },
    snakeCase: 'contaminated_water_at_camp_lejeune',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 3
  },
  {
    display: 'DIC - death, or accrued benefits - United States',
    queueDisplay: 'DIC for appellant in the United States',
    specialIssue: 'dicDeathOrAccruedBenefitsUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'dic_death_or_accrued_benefits_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true,
    queueSection: 'dicOrPension',
    queueSectionOrder: 1
  },
  {
    display: 'Education - GI Bill, dependents educational assistance, ' +
      'scholarship, transfer of entitlement',
    queueDisplay: 'Education (GI Bill, Dependents\' Educational Assistance, ' +
    'scholarship or transfer of entitlement)',
    specialIssue: 'educationGiBillDependentsEducationalAssistanceScholarship' +
      'TransferOfEntitlement',
    stationOfJurisdiction: null,
    snakeCase: 'education_gi_bill_dependents_educational_assistance_scholars',
    unhandled: {
      emailAddress: 'education',
      regionalOffice: 'education'
    },
    nonCompensation: true,
    queueSection: 'benefitType',
    queueSectionOrder: 1
  },
  {
    display: 'Foreign claim - compensation claims, dual claims, appeals',
    queueDisplay: 'Other foreign country',
    specialIssue: 'foreignClaimCompensationClaimsDualClaimsAppeals',
    stationOfJurisdiction: {
      key: '311',
      location: 'Pittsburgh, PA'
    },
    snakeCase: 'foreign_claim_compensation_claims_dual_claims_appeals',
    unhandled: null,
    queueSection: 'residence',
    queueSectionOrder: 4
  },
  {
    display: 'Foreign pension, DIC - Mexico, Central and South America, Caribbean',
    queueDisplay: 'DIC/Pension for appellant in Mexico, Central or South America or the Caribbean',
    specialIssue: 'foreignPensionDicMexicoCentralAndSouthAmericaCaribb',
    stationOfJurisdiction: null,
    snakeCase: 'foreign_pension_dic_mexico_central_and_south_america_caribb',
    unhandled: {
      emailAddress: ['AppealsPMC.VAVBASPL@va.gov', 'Hillary.Hernandez@va.gov'],
      regionalOffice: 'RO83'
    },
    nonCompensation: true,
    queueSection: 'dicOrPension',
    queueSectionOrder: 2
  },
  {
    display: 'Foreign pension, DIC - all other foreign countries',
    queueDisplay: 'DIC/Pension for appellant in any foreign country outside of Mexico, Central' +
    ' or South America or the Caribbean',
    specialIssue: 'foreignPensionDicAllOtherForeignCountries',
    stationOfJurisdiction: null,
    snakeCase: 'foreign_pension_dic_all_other_foreign_countries',
    unhandled: {
      emailAddess: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true,
    queueSection: 'dicOrPension',
    queueSectionOrder: 3
  },
  {
    display: 'Hearing - including travel board & video conference',
    specialIssue: 'hearingIncludingTravelBoardVideoConference',
    stationOfJurisdiction: 'regional',
    snakeCase: 'hearing_including_travel_board_video_conference',
    unhandled: null,
    nonCompensation: true
  },
  {
    display: 'Home Loan Guaranty',
    queueDisplay: 'Home loan guaranty',
    specialIssue: 'homeLoanGuaranty',
    stationOfJurisdiction: null,
    snakeCase: 'home_loan_guaranty',
    unhandled: {
      emailAddress: ['jennifer.Tillery@va.gov'],
      regionalOffice: 'RO88'
    },
    nonCompensation: true,
    queueSection: 'benefitType',
    queueSectionOrder: 2
  },
  {
    display: 'Incarcerated Veterans',
    queueDisplay: 'Incarcerated',
    specialIssue: 'incarceratedVeterans',
    stationOfJurisdiction: 'regional',
    snakeCase: 'incarcerated_veterans',
    unhandled: null,
    queueSection: 'about',
    queueSectionOrder: 2
  },
  {
    display: 'Insurance',
    specialIssue: 'insurance',
    stationOfJurisdiction: null,
    snakeCase: 'insurance',
    unhandled: {
      emailAddress: ['nancy.encarnado@va.gov'],
      regionalOffice: 'RO80'
    },
    nonCompensation: true,
    queueSection: 'benefitType',
    queueSectionOrder: 3
  },
  {
    display: 'Manlincon Compliance',
    node: <span><i>Manlincon</i> Compliance</span>,
    specialIssue: 'manlinconCompliance',
    stationOfJurisdiction: 'regional',
    snakeCase: 'manlincon_compliance',
    unhandled: null,
    nonCompensation: true,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 4
  },
  {
    display: 'Mustard Gas',
    specialIssue: 'mustardGas',
    stationOfJurisdiction: {
      key: '351',
      location: 'Muskogee, OK'
    },
    snakeCase: 'mustard_gas',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 6
  },
  {
    display: 'National Cemetery Administration',
    specialIssue: 'nationalCemeteryAdministration',
    stationOfJurisdiction: null,
    snakeCase: 'national_cemetery_administration',
    unhandled: {
      emailAddress: ['richard.byersII@va.gov'],
      regionalOffice: 'RO98'
    },
    nonCompensation: true,
    queueSection: 'benefitType',
    queueSectionOrder: 4
  },
  {
    display: 'Non-rating issue',
    queueDisplay: 'Non-rating issue (issue doesn\'t require a rating)',
    specialIssue: 'nonratingIssue',
    stationOfJurisdiction: 'regional',
    snakeCase: 'nonrating_issue',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 7
  },
  {
    display: 'Pension - United States',
    queueDisplay: 'Pension for appellant in United States',
    specialIssue: 'pensionUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'pension_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true,
    queueSection: 'dicOrPension',
    queueSectionOrder: 4
  },
  {
    display: 'Private Attorney or Agent',
    queueDisplay: 'Has a private attorney or agent',
    specialIssue: 'privateAttorneyOrAgent',
    stationOfJurisdiction: 'regional',
    snakeCase: 'private_attorney_or_agent',
    unhandled: null,
    queueSection: 'about',
    queueSectionOrder: 1
  },
  {
    display: 'Radiation',
    specialIssue: 'radiation',
    stationOfJurisdiction: 'regional',
    snakeCase: 'radiation',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 8
  },
  {
    display: 'Rice Compliance',
    node: <span><i>Rice</i> Compliance</span>,
    specialIssue: 'riceCompliance',
    stationOfJurisdiction: 'regional',
    snakeCase: 'rice_compliance',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 9
  },
  {
    display: 'Spina Bifida',
    queueDisplay: 'Spina bifida (chapter 18)',
    specialIssue: 'spinaBifida',
    stationOfJurisdiction: 'regional',
    snakeCase: 'spina_bifida',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 10
  },
  {
    display: 'U.S. Territory claim - American Samoa, Guam, Northern ' +
      'Mariana Islands (Rota, Saipan & Tinian)',
    queueDisplay: 'American Samoa, Guam, Northern ' +
      'Mariana Islands (Rota, Saipan and Tinian)',
    specialIssue: 'usTerritoryClaimAmericanSamoaGuamNorthern' +
      'MarianaIslandsRotaSaipanTinian',
    stationOfJurisdiction: {
      key: '459',
      location: 'Honolulu, HI'
    },
    snakeCase: 'us_territory_claim_american_samoa_guam_northern_mariana_isla',
    unhandled: null,
    queueSection: 'residence',
    queueSectionOrder: 1
  },
  {
    display: 'U.S. Territory claim - Philippines',
    queueDisplay: 'Philippines',
    specialIssue: 'usTerritoryClaimPhilippines',
    stationOfJurisdiction: {
      key: '358',
      location: 'Manila, Philippines'
    },
    snakeCase: 'us_territory_claim_philippines',
    unhandled: null,
    queueSection: 'residence',
    queueSectionOrder: 2
  },
  {
    display: 'U.S. Territory claim - Puerto Rico and Virgin Islands',
    queueDisplay: 'Puerto Rico or Virgin Islands',
    specialIssue: 'usTerritoryClaimPuertoRicoAndVirginIslands',
    stationOfJurisdiction: {
      key: '355',
      location: 'San Juan, Puerto Rico'
    },
    snakeCase: 'us_territory_claim_puerto_rico_and_virgin_islands',
    unhandled: null,
    queueSection: 'residence',
    queueSectionOrder: 3
  },
  {
    display: 'VAMC',
    queueDisplay: 'Veterans Administration Medical Center (VAMC)',
    specialIssue: 'vamc',
    stationOfJurisdiction: null,
    snakeCase: 'vamc',
    unhandled: {
      emailAddress: ['Travis.Richardson@va.gov'],
      regionalOffice: 'RO99'
    },
    nonCompensation: true,
    queueSection: 'benefitType',
    queueSectionOrder: 4
  },
  {
    display: 'Veterans Readiness and Employment',
    queueDisplay: 'Veterans Readiness and Employment (VR&E)',
    specialIssue: 'vocationalRehab',
    snakeCase: 'vocational_rehab',
    stationOfJurisdiction: 'regional',
    nonCompensation: true,
    queueSection: 'benefitType',
    queueSectionOrder: 5
  },
  {
    display: 'Waiver of Overpayment',
    queueDisplay: 'Waiver of overpayment',
    specialIssue: 'waiverOfOverpayment',
    stationOfJurisdiction: null,
    snakeCase: 'waiver_of_overpayment',
    unhandled: {
      emailAddress: 'COWC',
      regionalOffice: 'COWC'
    },
    nonCompensation: true,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 11
  }
];

// Special Issues added in 2020-Spring for AMA appeals use only
export const AMA_SPECIAL_ISSUES = [
  {
    display: 'Burn Pit',
    queueDisplay: 'Burn Pit',
    specialIssue: 'burnPit',
    snakeCase: 'burn_pit',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 2,
    isAmaRelevant: true
  },
  {
    display: 'Blue Water',
    queueDisplay: 'Blue Water',
    specialIssue: 'blueWater',
    snakeCase: 'blue_water',
    unhandled: null,
    queueSection: 'issuesOnAppeal',
    queueSectionOrder: 1,
    isAmaRelevant: true
  },
  {
    node: <b>No Special Issues</b>,
    display: 'No Special Issues',
    queueDisplay: 'No Special Issues',
    specialIssue: 'noSpecialIssues',
    snakeCase: 'no_special_issues',
    unhandled: null,
    queueSection: 'noSpecialIssues'
  }
];

export default SPECIAL_ISSUES;

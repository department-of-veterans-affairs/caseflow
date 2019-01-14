import React from 'react';

const SPECIAL_ISSUES = [
  {
    display: 'Contaminated Water at Camp LeJeune',
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: {
      key: '327',
      location: 'Louisville, KY'
    },
    snakeCase: 'contaminated_water_at_camp_lejeune',
    unhandled: null,
    section: 'issuesOnAppeal'
  },
  {
    display: 'DIC - death, or accrued benefits - United States',
    specialIssue: 'dicDeathOrAccruedBenefitsUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'dic_death_or_accrued_benefits_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true
  },
  {
    display: 'Education (GI Bill, Dependents Educational Assistance, ' +
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
    section: 'benefitType'
  },
  {
    display: 'Other foreign country',
    specialIssue: 'foreignClaimCompensationClaimsDualClaimsAppeals',
    stationOfJurisdiction: {
      key: '311',
      location: 'Pittsburgh, PA'
    },
    snakeCase: 'foreign_claim_compensation_claims_dual_claims_appeals',
    unhandled: null,
    section: 'residence'
  },
  {
    display: 'DIC/Pension for appellant in Mexico, Central or South America or the Caribbean',
    specialIssue: 'foreignPensionDicMexicoCentralAndSouthAmericaCaribb',
    stationOfJurisdiction: null,
    snakeCase: 'foreign_pension_dic_mexico_central_and_south_america_caribb',
    unhandled: {
      emailAddress: ['AppealsPMC.VAVBASPL@va.gov', 'Hillary.Hernandez@va.gov'],
      regionalOffice: 'RO83'
    },
    nonCompensation: true,
    section: 'dicOrPension'
  },
  {
    display: 'DIC/Pension for appellant in any foreign country outside of Mexico, Central' +
      'or South America, or the Caribbean',
    specialIssue: 'foreignPensionDicAllOtherForeignCountries',
    stationOfJurisdiction: null,
    snakeCase: 'foreign_pension_dic_all_other_foreign_countries',
    unhandled: {
      emailAddess: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true,
    section: 'dicOrPension'
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
    display: 'Home loan guaranty',
    specialIssue: 'homeLoanGuaranty',
    stationOfJurisdiction: null,
    snakeCase: 'home_loan_guaranty',
    unhandled: {
      emailAddress: ['jennifer.Tillery@va.gov'],
      regionalOffice: 'RO88'
    },
    nonCompensation: true,
    section: 'benefitType'
  },
  {
    display: 'Incarcerated Veterans',
    specialIssue: 'incarceratedVeterans',
    stationOfJurisdiction: 'regional',
    snakeCase: 'incarcerated_veterans',
    unhandled: null
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
    section: 'benefitType'
  },
  {
    display: 'Manlincon Compliance',
    node: <span><i>Manlincon</i> Compliance</span>,
    specialIssue: 'manlinconCompliance',
    stationOfJurisdiction: 'regional',
    snakeCase: 'manlincon_compliance',
    unhandled: null,
    nonCompensation: true,
    section: 'issuesOnAppeal'
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
    section: 'issuesOnAppeal'
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
    section: 'benefitType'
  },
  {
    display: 'Non-rating issue (issue doesn\'t require a rating)',
    specialIssue: 'nonratingIssue',
    stationOfJurisdiction: 'regional',
    snakeCase: 'nonrating_issue',
    unhandled: null,
    section: 'issuesOnAppeal'
  },
  {
    display: 'Pension for appellant in United States',
    specialIssue: 'pensionUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'pension_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true,
    section: 'dicOrPension'
  },
  {
    display: 'DIC for appellant in United States',
    specialIssue: 'dicUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'DIC_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    },
    nonCompensation: true,
    section: 'dicOrPension'
  },
  {
    display: 'Has a private Attorney or Agent',
    specialIssue: 'privateAttorneyOrAgent',
    stationOfJurisdiction: null,
    snakeCase: 'private_attorney_or_agent',
    unhandled: null,
    section: 'about'
  },
  {
    display: 'Radiation',
    specialIssue: 'radiation',
    stationOfJurisdiction: 'regional',
    snakeCase: 'radiation',
    unhandled: null,
    section: 'issuesOnAppeal'
  },
  {
    display: 'Rice Compliance',
    node: <span><i>Rice</i> Compliance</span>,
    specialIssue: 'riceCompliance',
    stationOfJurisdiction: 'regional',
    snakeCase: 'rice_compliance',
    unhandled: null,
    section: 'issuesOnAppeal'
  },
  {
    display: 'Spina bifida (chapter 18)',
    specialIssue: 'spinaBifida',
    stationOfJurisdiction: 'regional',
    snakeCase: 'spina_bifida',
    unhandled: null,
    section: 'issuesOnAppeal'
  },
  {
    display: 'American Samoa, Guam, Northern ' +
      'Mariana Islands (Rota, Saipan & Tinian)',
    specialIssue: 'usTerritoryClaimAmericanSamoaGuamNorthern' +
      'MarianaIslandsRotaSaipanTinian',
    stationOfJurisdiction: {
      key: '459',
      location: 'Honolulu, HI'
    },
    snakeCase: 'us_territory_claim_american_samoa_guam_northern_mariana_isla',
    unhandled: null,
    section: 'residence'
  },
  {
    display: 'Philippines',
    specialIssue: 'usTerritoryClaimPhilippines',
    stationOfJurisdiction: {
      key: '358',
      location: 'Manila, Philippines'
    },
    snakeCase: 'us_territory_claim_philippines',
    unhandled: null,
    section: 'residence'
  },
  {
    display: 'Puerto Rico or Virgin Islands',
    specialIssue: 'usTerritoryClaimPuertoRicoAndVirginIslands',
    stationOfJurisdiction: {
      key: '355',
      location: 'San Juan, Puerto Rico'
    },
    snakeCase: 'us_territory_claim_puerto_rico_and_virgin_islands',
    unhandled: null,
    section: 'residence'
  },
  {
    display: 'Veterans Administration Medical Center (VAMC)',
    specialIssue: 'vamc',
    stationOfJurisdiction: null,
    snakeCase: 'vamc',
    unhandled: {
      emailAddress: ['Travis.Richardson@va.gov'],
      regionalOffice: 'RO99'
    },
    nonCompensation: true,
    section: 'benefitType'
  },
  {
    display: 'Vocational Rehabilitation and Employment (VR&E)',
    specialIssue: 'vocationalRehab',
    snakeCase: 'vocational_rehab',
    stationOfJurisdiction: 'regional',
    nonCompensation: true,
    section: 'benefitType'
  },
  {
    display: 'Waiver of overpayment',
    specialIssue: 'waiverOfOverpayment',
    stationOfJurisdiction: null,
    snakeCase: 'waiver_of_overpayment',
    unhandled: {
      emailAddress: 'COWC',
      regionalOffice: 'COWC'
    },
    nonCompensation: true,
    section: 'issuesOnAppeal'
  },
  {
    display: 'Committee on Waivers and Compromises',
    specialIssue: 'committeeOnWaiversAndCompromises',
    stationOfJurisdiction: null,
    snakeCase: 'committee_on_waivers_and_compromises',
    unhandled: {
      emailAddress: 'COWC',
      regionalOffice: 'COWC'
    },
    nonCompensation: true,
    section: 'issuesOnAppeal'
  }
];

export default SPECIAL_ISSUES;

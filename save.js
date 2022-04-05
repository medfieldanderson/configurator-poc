const PMS_BASE = 'http://open-int-planmgmtservice.qa.navinet.local';
const PMS_PATH = '/api/management/plans';
const PMS = `${PMS_BASE}${PMS_PATH}`;
const URL_IDENTIFIER = 'Aries';
const PRODUCT = 'Authorizations';
const CONFIG = 'Authorization-Submission-Ui';
const X_API_VERSION = '1';

// http://open-int-planmgmtservice.qa.navinet.local/api/management/plans/{{url-identifier}}/products/authorizations/configurations/authorization-submission-ui
const url =
  `${PMS}/${URL_IDENTIFIER}/products/${PRODUCT}/configurations/${CONFIG}`.toLowerCase();

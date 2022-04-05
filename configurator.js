const getStuff = () => {
  var myHeaders = new Headers();
  myHeaders.append('Content-Type', 'application/json');
  myHeaders.append('x-api-version', '1');

  var urlencoded = new URLSearchParams();

  var requestOptions = {
    method: 'GET',
    headers: myHeaders,
    body: urlencoded,
    redirect: 'follow',
  };

  fetch(
    'http://open-int-planmgmtservice.qa.navinet.local/api/management/plans/aries/products/authorizations/configurations/authorization-submission-ui',
    requestOptions
  )
    .then((response) => response.text())
    .then((result) => console.log(result))
    .catch((error) => console.log('error', error));
};

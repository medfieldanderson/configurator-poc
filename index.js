// VANILLA JAVASCRIPT ON CLIENT
// IMPORT AXIOS VIA HTML HEADER

// ES6
// import axios from 'axios';
// CommonJS
// const axios = required('axios');
// link in html for vanilla javascript
// const { default: axios } = require('axios');

// Create JSON from data in controls.
// https://www.npmjs.com/package/edit-json-file

import { JSONPath } from "./node_modules/jsonpath-plus/dist/index-browser-esm.js";

const PMS_BASE = "http://open-int-planmgmtservice.qa.navinet.local";
const PMS_PATH = "/api/management/plans";
const PMS = `${PMS_BASE}${PMS_PATH}`;
const URL_IDENTIFIER = "Aries";

let PRODUCT = "Authorizations";
PRODUCT = "EB2";

let CONFIG = "Authorization-Submission-Ui";
CONFIG = "UI";

const X_API_VERSION = "1";

const _dynamicdiv = document.getElementsByClassName("dynamic-ui")[0];

let _schemaObj = {};
let _level = 0;

// http://open-int-planmgmtservice.qa.navinet.local/api/management/plans/{{url-identifier}}/products/authorizations/configurations/authorization-submission-ui
const urlz =
  `${PMS}/${URL_IDENTIFIER}/products/${PRODUCT}/configurations/${CONFIG}`.toLowerCase();

const getConfig = async (url, config) => {
  try {
    const configJson = await axios.get(url, config);
    return configJson.data;
  } catch (error) {
    console.log(error);
    throw error;
  }
};

const main = async (url) => {
  const json = document.getElementsByClassName("json")[0];
  const schema = document.getElementsByClassName("schema")[0];
  const ariesJson = document.getElementsByClassName("ariesJson")[0];

  let urlJson = "./auth-sub-ui.json";
  let urlSchema = "./auth-sub-ui-schema.json";
  // OVERRIDE with EB2
  urlJson = "./eb2-ui.json";
  urlSchema = "./eb2-ui-schema.json";

  const config = {
    headers: {
      "Content-Type": "application/json",
      // x-api-version is a non-standard header, so browser will always invoke preflight.
      // unfortunately, cannot get config without x-api-version.
      "x-api-version": `${X_API_VERSION}`,
      "Target-URL": urlz,
      // This should be done on the server. Adding this here could result in an unnecessary PREFLIGHT check. Get rid of it.
      // "Access-Control-Allow-Origin": "*",
      // see https://stackoverflow.com/questions/35553500/xmlhttprequest-cannot-load-xxx-no-access-control-allow-origin-header
    },
  };

  try {
    _schemaObj = await getConfig(urlSchema, config);
    schema.textContent = JSON.stringify(_schemaObj);

    // JSONPath testing output to console
    let targetJson = await getConfig(urlJson, config);
    json.textContent = JSON.stringify(targetJson);

    try {
      const feature_xri = JSONPath({ path: "$.feature_xri", json: targetJson });

      console.log(`FEATURE XRI:  ${feature_xri}`);

      const resource_path = JSONPath({
        path: "$.access_control_descriptors.inquiry.resource_path",
        json: targetJson,
      });

      console.log(`RESOURCE PATH:  ${resource_path}`);

    } catch (error) {

      console.log(error);
    }

    targetJson = await getConfig("http://localhost:3000", config);
    console.log(`TARGET JSON:  ${JSON.stringify(targetJson)}`);
    ariesJson.textContent = JSON.stringify(targetJson);
  } catch (error) {
    console.log(`ERROR:  ${error}`);
    const errDiv = document.querySelector(".error");
    errDiv.innerHTML = error;
  }

  // each object has required fields; each required field has corresponding properties (type)
  // if the type is object it should invoke the same methods as the root
  let root = _schemaObj;
  processRoot(root);
};

const processRoot = (root) => {
  let required = root.required;
  let properties = root.properties;

  processObject("root", required, properties);
};

const processObject = (parent, required, properties) => {
  // loop through all the items in the object
  addLabelForObject(parent);
  _level += 1; // div class="level0"></div>      maybe add div around objects here instead.
  required.forEach((item) => {
    return processRequired(item, properties[item]);
  });
  _level -= 1; //</div>
};

const processArrayItems = (item, property) => {
  addLabelForArray(item, property);
  addArrayAsDiv(item, property);

  console.log(
    `PROCESS ARRAY ITEMS:  ${item} | ${
      property.items
    } | ${typeof property.items} `
  );
  // property.items.anyOf.forEach((item) => {
  //   console.log(item);
  //   return processObject(parent, property.required, property.properties);
  // });
};

const processRequired = (item, property) => {
  switch (property.type) {
    case "string":
      addInputText(item, property);
      // console.log(`${item} -> input[text] ${property.type}`);
      break;

    case "boolean":
      addCheckbox(item, property);
      // console.log(`${item}? -> checkbox  ${property.type}`);
      break;

    case "integer":
      addInputNumber(item, property);
      // console.log(`${item} is a NUMBER?  What control will this be?`);
      break;

    case "array":
      processArrayItems(item, property);
      // _level += 1; // div class="level0"></div>      maybe add div around objects here instead.
      // processObject(item, property.required, property.properties);
      // _level -= 1; //</div>

      console.log(
        `${item} is an ARRAY of ${typeof item[0]}s.  Which control???  ${
          property.type
        }`
      );
      break;

    case "object":
      // console.log(`Object is ${item}`);

      processObject(item, property.required, property.properties);

      break;

    default:
      return console.log(
        `****** ITEM:  ${item} | UNKNOWN PROPERTY TYPE:  ${property.type}`
      );
  }
};

const addLabelForObject = (value) => {
  const label = document.createElement("label");
  label.setAttribute("class", `level${_level} object`);
  label.textContent = `${value}`;
  _dynamicdiv.appendChild(label);
};

const addLabelForArray = (item, property) => {
  const arrayType = property.items.anyOf[0].type;
  const label = document.createElement("label");
  label.setAttribute("class", `level${_level} array`);
  label.textContent = `${item} -  array of ${arrayType}s`;

  const textArea = document.createElement("textarea");

  // property.examples[0].forEach((example) => console.log(example));
  property.examples[0].forEach((example) => {
    console.log(example);
    textArea.value += `${example}\n`;
  });

  label.append(textArea);
  _dynamicdiv.appendChild(label);
};

const addInputText = (fieldValue, property) => {
  const label = document.createElement("label");
  label.setAttribute("for", property["$id"]);
  label.setAttribute("class", `level${_level}`);
  label.textContent = `${fieldValue}: `;

  const input = document.createElement("input");
  input.type = "text";
  input.id = property["$id"];
  // input.className = `level${_level}`; // handle class that indents (i.e. "level0") at label above only

  label.appendChild(input);
  _dynamicdiv.appendChild(label);
};

const addCheckbox = (fieldValue, property) => {
  const label = document.createElement("label");
  label.setAttribute("for", property["$id"]);
  label.setAttribute("class", `level${_level}`);
  label.textContent = `${fieldValue}:`;

  const input = document.createElement("input");
  input.setAttribute("type", "checkbox");
  input.setAttribute("id", property["$id"]);
  // input.setAttribute("class", `level${_level}`);

  label.appendChild(input);
  _dynamicdiv.appendChild(label);
};

const addInputNumber = (fieldValue, property) => {
  const label = document.createElement("label");
  label.setAttribute("for", property["$id"]);
  label.setAttribute("class", `level${_level}`);
  label.textContent = `${fieldValue}: `;

  const input = document.createElement("input");
  input.type = "number";
  input.id = property["$id"];
  input.className = `level${_level}`;

  // DEFAULT FOR NOW TO 0
  input.value = 0;

  label.appendChild(input);
  _dynamicdiv.appendChild(label);
};

const addArrayAsDiv = (fieldValue, property) => {
  console.log(
    `FIELD VALUE:  ${fieldValue} | PROPERTY:  ${JSON.stringify(property)}`
  );

  const div = document.createElement("div");
  div.setAttribute("class", `level${_level}`);
  div.setAttribute("title", fieldValue);
  div.textContent = JSON.stringify(property);

  _dynamicdiv.appendChild(div);
};

main();

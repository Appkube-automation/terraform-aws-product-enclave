'use strict'
exports.handler = function (event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
    },
    body: '<h2>Welcome to Secure API...</h2>',
  }
  callback(null, response)
}
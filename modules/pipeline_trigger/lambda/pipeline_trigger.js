const AWS = require('aws-sdk');
const codepipeline = new AWS.CodePipeline({ apiVersion: '2015-07-09' });
const region = "us-east-1"

exports.handler = async function (event, context, callback) {

  console.log("EVENT: \n" + JSON.stringify(event, null, 2));
  let pipeline_name = `codepipeline-${process.env.APP_NAME}-${process.env.ENV_NAME}`
  console.log(`PIPELINE:${pipeline_name}`);
  var params = {
    name: `${pipeline_name}`
  };
  let pipeline_execution = await codepipeline.startPipelineExecution(params, function (err, data) {
    if (err) {
      console.log(`ERROR: Failed to start pipeline codepipeline-${pipeline_name}`);
      console.log(err, err.stack)
    }
    else {
      console.log(`STARTING PIPELINE: ${pipeline_name}`)
      console.log("PIPELINE_EXECUTION: \n" +  JSON.stringify(data, null, 2))
    };
  }).promise();
}